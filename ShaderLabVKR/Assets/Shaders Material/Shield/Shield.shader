Shader "Hidden/Shield"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_Intensity("Intensity", Range(0,200)) = 3.0
		_BiasWidth("Bias Width", Range(0,2)) = 3.0
		_Distort("Distort", Range(0, 500)) = 1.0
		_IntersectThreshold("Line of intersection", range(0,1)) = 0.1
		_ScrollSpeedU("Scroll U Speed", float) = 2
		_ScrollSpeedV("Scroll V Speed", float) = 0
	}
	SubShader
	{ 
		Tags
		{
			"IgnoreProjector" = "True"
			"Queue" = "Overlay"
			"RenderType" = "Transparent"
			
		}

		GrabPass
		{
			"_GPTexField"
		}
		Pass
		{
			Lighting Off
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				fixed4 vertex : POSITION;
				fixed3 uv : TEXCOORD0;
				fixed4 normal: NORMAL;
			};

			struct v2f
			{
				fixed2 uv : TEXCOORD0;
				fixed4 vertex : SV_POSITION;
				fixed3 rimPower :TEXCOORD1;
				fixed4 screenPos: TEXCOORD2;
				fixed4 grabPassUV: TEXCOORD3;
			};

			sampler2D _CameraDepthTexture;
			
			sampler2D _MainTex;
			fixed4 _MainTex_ST;			
			sampler2D _GPTexField;
			fixed4 _GPTexField_ST;
			fixed4 _GPTexField_TexelSize;
			
			fixed4 _Color;
			fixed _Intensity;
			fixed _BiasWidth;
			fixed _Distort;
			fixed _IntersectThreshold;
			fixed _ScrollSpeedU;
			fixed _ScrollSpeedV;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv =  TRANSFORM_TEX(v.uv, _MainTex);
				
				float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
				float NdotV = 1 - saturate(dot(v.normal, viewDir));
				o.rimPower = smoothstep(1 - _BiasWidth, 1.0, NdotV) * 0.5f;
				
				o.screenPos = ComputeScreenPos(o.vertex);
                o.grabPassUV = ComputeGrabScreenPos(o.vertex);
				
				o.uv.x += _Time * _ScrollSpeedU;
				o.uv.y += _Time * _ScrollSpeedV;
				return o;
			}

			//переменная, указывающую, обращена ли отображаемая поверхность к камере
			float4 frag (v2f i, float facing : VFACE) : SV_Target
			{
				float3 mainColor = tex2D(_MainTex, i.uv);
				
				i.grabPassUV.xy += (mainColor * 2 - 1) * _Distort * _GPTexField_TexelSize.xy;
				float3 distortColor = tex2Dproj(_GPTexField, i.grabPassUV);
				distortColor *= _Color * _Color.a + 1;
				
				//находим пересечение
				float linearDepth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture,i.screenPos).r);
				float lineIntersect = saturate(abs(linearDepth - i.screenPos.w)/_IntersectThreshold);
				
				//подсвечиваем пересечение
				i.rimPower *= lineIntersect * clamp(0, 1, facing);
				mainColor *= _Color * pow(_Intensity, i.rimPower) ;
				
				//прозрачность щита
				mainColor = lerp(distortColor, mainColor, i.rimPower.r);
				mainColor += (1 - lineIntersect) * (facing > 0 ? 0.03 : 0.3) * _Color * _Intensity;
				return float4(mainColor, 0.9);
			}
			ENDCG
		}
	}
}