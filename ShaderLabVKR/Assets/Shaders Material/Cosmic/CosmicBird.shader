Shader "Unlit/CosmicBird"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
		_MaskTex("Mask Texture", 2D) = "white" {}
		_MaskColor("Mask Color", Color) = (1,1,1,1)
		_MaskReplace("Mask Replace Texture", 2D) = "white" {}
		_MaskScale("Mask Scale", float) = 1.0
		_Speed("Mask Texture Speed", float) = 0.15
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}
    SubShader
    {
    	Tags 
		{
			"Queue"="AlphaTest" 
			"IgnoreProjector"="True" 
			"RenderType"="TransparentCutout"
		}
        
        LOD 100

        Pass
        {
			Cull Off
			Tags 
			{ 
				"RenderType"="Opaque"
				"LightMode" = "ForwardBase"		
			}
		
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 texCoord  : TEXCOORD0;
            };

            struct v2f 
            {
                float2 texCoord  : TEXCOORD0;
				float3 normal : NORMAL;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _MaskReplace;
            float4 _MaskColor;
            float _MaskScale;
            float _Speed;
            float4 _MainTex_ST;
			float4 _LightColor0;
			fixed _Cutoff;

            v2f  vert (appdata i)
            {
                v2f o;

				o.pos = UnityObjectToClipPos(i.vertex);
				o.normal = UnityObjectToWorldNormal(i.normal);

				o.texCoord = i.texCoord;

				return o;
            }

            fixed4 frag (v2f  i) : SV_Target
            {
                // простое освещение
            	float3 normalDir = normalize(i.normal);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float NdotL = max(0.0, dot(normalDir, lightDir) * _LightColor0);
				float3 lighting = NdotL * _LightColor0.rgb;
				lighting += ShadeSH9(half4(i.normal,1));

				//прозрачность
				float4 albedo = tex2D(_MainTex, i.texCoord.xy);
				clip(albedo.a - _Cutoff);
            	
            	// настройка позиции замещающей текстуры
				float2 screenPos = ComputeScreenPos(i.pos).xy / _ScreenParams.xy;
				float2 cosmicPos = screenPos * _MaskScale;
				cosmicPos += _Time * _Speed;
				
				// маска
				float isMask = tex2D(_MaskTex, i.texCoord.xy) == _MaskColor;
				float4 cosmTex = tex2D(_MaskReplace, cosmicPos);
				
				//итоговое
				float3 rgb = (1 - isMask) * albedo  * lighting
            				+ isMask * cosmTex* float4(1,1,1,1);
				return float4(rgb, 1.0);
            }
            ENDCG
        }
    }
}
