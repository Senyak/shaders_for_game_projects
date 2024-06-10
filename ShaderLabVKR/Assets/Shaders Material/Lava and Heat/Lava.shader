Shader "Hidden/Lava"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
        _FlowMap ("Flow Map", 2D) = "grey" {}
        _Speed ("Speed of Flow", Range(-1, 1)) = 0.2
		
		_Intensity("Intensity", Range(0,200)) = 3.0
		_Power("Power", Range(0, 1)) = 0.4
		_LineOfIntersect("Line of intersection", float) = 0.1 
		_ScrollXSpeed("Scroll X Speed", float) = 2
		_ScrollYSpeed("Scroll Y Speed", float) = 0
		
        _EmissionTex ("Emission texture", 2D) = "gray" {}
        _EmiVal ("Intensity", float) = 0.
        [HDR]_EmiColor ("Color", color) = (1., 1., 1., 1.)
	}
	SubShader
	{ 
		Tags
		{
			"IgnoreProjector" = "True"
			"Queue" = "Overlay"
			"RenderType" = "Transparent"
			
		}
		
		Pass
		{
			ZWrite On
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 uv : TEXCOORD0;
				float4 normal: NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float2 uvDistrot :TEXCOORD1;
				float4 screenPos: TEXCOORD2;
			};

			sampler2D _CameraDepthTexture;
			
			sampler2D _MainTex;
			float4 _MainTex_ST;	
			float4 _MainTex_TexelSize;	
            sampler2D _FlowMap;	
			float4 _FlowMap_ST;
			
			float4 _Color;
			float _Intensity;
            float _Power;
			float _LineOfIntersect;
			float _ScrollXSpeed;
			float _ScrollYSpeed;
            float _Speed;

			
            sampler2D _EmissionTex;
            float4 _EmissionTex_ST;
            float4 _EmiColor;
            float _EmiVal;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				o.uvDistrot = TRANSFORM_TEX(v.uv, _FlowMap);
				o.screenPos = ComputeScreenPos(o.vertex);
				
				o.uv.x += _Time * _ScrollXSpeed;
				o.uv.y += _Time * _ScrollYSpeed;
				return o;
			}

			//переменная, указывающую, обращена ли отображаемая поверхность к камере
			float4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{
				float3 flowTex = (tex2D(_FlowMap, i.uvDistrot) * 2 - 1) * _Speed;
 
                float startPos = frac(_Time.y * 0.25 + 0.5);
                float endPos = frac(_Time.y * 0.25);
                float linearDiff = abs((0.5 - startPos)/0.5);
 
                float3 firstTex = tex2D(_MainTex, i.uv - flowTex.xy * startPos);
                float3 secondTex = tex2D(_MainTex, i.uv - flowTex.xy * endPos);
                float3 mainColor = lerp(firstTex, secondTex, linearDiff);

				float2 emiPos =TRANSFORM_TEX(i.uv, _EmissionTex);
				float4 emi = tex2D(_EmissionTex, emiPos).r;
				emi *= _EmiColor * ((sin(_Time*_EmiVal).r + 1.0)/2.0);
				
                mainColor.rgb += emi.rgb;
				
				//находим пересечение
				float depthLin = LinearEyeDepth(tex2Dproj(_CameraDepthTexture,i.screenPos).r);
				float lineIntersect = saturate(abs(depthLin - i.screenPos.w) / _LineOfIntersect);
				
				//применяем цвет в зависимости от значения пересечения
				//mainColor *= _Color * pow(_Intensity, _Power) ;
				//mainColor = lerp(_Color, mainColor, _Power);
				mainColor += (1 - lineIntersect) * (facing > 0 ? 0.03 : 0.3) * _Color * _Intensity;
				return float4(mainColor, 0.9);
			}
			ENDCG
		}
	}
}