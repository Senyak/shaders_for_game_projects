Shader "Hidden/Water"
{
    Properties
    {
        _GradientBright("Gradient Bright", Color) = (1,1,1,0.6)
        _GradientDark("Gradient Dark", Color) = (0.5,0.5,0.5,0.7)
        _MaxDepth("Max Depth ", Float) = 1
        
        _NoiseTex("Noise Tex", 2D) = "white" {}
        _NoiseAmount("Noise Amount", Range(0, 1)) = 0.777
        _FoamMaxWidth("Foam Max Width", Float) = 0.4
        _FoamMinWidth("Foam Min Width", Float) = 0.04
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _ScrollSpeed("Noise Scroll Speeed", Vector) = (0.03, 0.03, 0, 0)
                
        _DistortionTex("Distortion Tex", 2D) = "white" {}	
        _DistortionAmount("Distortion Amount", Range(0, 1)) = 0.27
        
        _WaveSpeed("Wave Speed", float) = 1.0
		_WaveAmp("Wave Amplitude", float) = 0.2
    }
    SubShader
    {
        Tags
        {
	        "Queue" = "Transparent"
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define SMOOTH_FOAM 0.03

            struct appdata
            {
                float4 uv : TEXCOORD0;
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 noiseUV : TEXCOORD0;
                float2 distortUV : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 viewNormal : NORMAL;
            };

            float4 _GradientBright;
            float4 _GradientDark;
            float _MaxDepth;

            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            sampler2D _DistortionTex;
            float4 _DistortionTex_ST;
            
            float _NoiseAmount;
            float _FoamMaxWidth;
            float _FoamMinWidth;
            float4 _FoamColor;
            float2 _ScrollSpeed;

            float _DistortionAmount;
			float  _WaveSpeed;
			float  _WaveAmp;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.distortUV = TRANSFORM_TEX(v.uv, _DistortionTex);
                
                float texNoise = tex2Dlod(_NoiseTex, float4(v.uv.xy, 0, 0));
                o.vertex.y += sin(_Time * _WaveSpeed* texNoise) * _WaveAmp;
                o.vertex.x += cos(_Time * _WaveSpeed * texNoise) * _WaveAmp;

                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //определяем удаленность плоскости воды от поверхности дна
                float4 depthPos = UNITY_PROJ_COORD(i.screenPos);
				float texDepth = tex2Dproj(_CameraDepthTexture, depthPos).r;
                float waterDepth = LinearEyeDepth(texDepth);
                float depthDiff = waterDepth - i.screenPos.w;
                float waterDepthDiff = saturate(depthDiff / _MaxDepth);
                
                //рассчет цвета воды
                float4 waterColor = lerp(_GradientBright, _GradientDark, waterDepthDiff);

                //натройка нормалей               
                float3 camerasNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPos));
                float3 NdotV = saturate(dot(camerasNormal, i.viewNormal));

                //отображение пены
                float foamWidth = lerp(_FoamMaxWidth, _FoamMinWidth, NdotV);
                float foamWidthDiff = saturate(depthDiff / foamWidth);
                float noiseAmount = foamWidthDiff * _NoiseAmount;
                
                //сглаживание применения шума
                float2 texDistort = (tex2D(_DistortionTex, i.distortUV).xy * 2 - 1) * _DistortionAmount;
                float2 noiseUV = float2((i.noiseUV.x + _Time.y * _ScrollSpeed.x) + texDistort.x,
                                        (i.noiseUV.y + _Time.y * _ScrollSpeed.y) + texDistort.y);
                float texNoise = tex2D(_NoiseTex, noiseUV).r;
                
                float foamAmount = smoothstep(noiseAmount - SMOOTH_FOAM, noiseAmount + SMOOTH_FOAM, texNoise);
                               
                //прозрачность воды
                _FoamColor.a *= foamAmount;
                float4 color = _FoamColor * _FoamColor.a  + waterColor * (1 - _FoamColor.a);
	            
                //return float4(waterDepthDiff, waterDepthDiff,waterDepthDiff,1.0);
                return color;
                //return waterColor + _FoamColor.a;
            }
            ENDCG
        }
    }
}