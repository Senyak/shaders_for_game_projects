Shader "Unlit/Heat"
{
    Properties
	{
		_MaskTexture ("Mask texture", 2D) = "white" {}
        _DistortionGuide("Distortion guide", 2D) = "bump" {}
        _DistortionAmount("Distortion amount", float) = 0
		_Speed("Distort Speed", float) = 1.0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"DisableBatching" = "True"
		}

		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		GrabPass
        {
            "_GPTex_Heat"
        }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
                float2 distortionUV : TEXCOORD1;
                float4 grabPassUV : TEXCOORD2;
			};

			
            sampler2D _GPTex_Heat;
            sampler2D _MaskTexture;
            float4 _MaskTexture_ST;
			float _DistortionAmount;
            sampler2D _DistortionGuide;
            float4 _DistortionGuide_ST;
			float _Speed;

			
			v2f vert (appdata v)
			{
				v2f o;
				
				//поворачиваем плоскость к камере
				float3 vpos = mul(unity_ObjectToWorld, v.vertex.xyz);
				float4 worldPos = mul(UNITY_MATRIX_M, float4(0, 0, 0, 1));
				
				float4 viewPos = mul(UNITY_MATRIX_V, worldPos) + float4(vpos, 0);
				float4 outPos = mul(UNITY_MATRIX_P, viewPos);
				o.vertex = outPos;

				//настраиваем искажение
				o.uv = TRANSFORM_TEX(v.uv, _MaskTexture);
                o.distortionUV = TRANSFORM_TEX(v.uv, _DistortionGuide);
				o.distortionUV.x += cos(_Time.x)* _Speed;
                o.distortionUV.y += sin(_Time.x)* _Speed ;
                o.grabPassUV = ComputeGrabScreenPos(o.vertex);

				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float mask = tex2D(_MaskTexture, i.uv).x;
				
                float2 distortion = tex2D(_DistortionGuide, i.distortionUV).xy;
                distortion *= _DistortionAmount * mask;
                i.grabPassUV.xy += distortion;
				
                float4 col = tex2Dproj(_GPTex_Heat, i.grabPassUV);
                return col;
			}
			ENDCG
		}
	}
}
