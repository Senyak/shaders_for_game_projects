Shader "Custom/Aniso"
{
    Properties
    {
        _MainTint ("Diffuse Tint", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		[HDR]_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		_Specular ("Specular Amount", Range(0,1)) = 0.5
		_SpecPower ("Specular Power", Range(0,1)) = 0.5
		_AnisoDir ("Anisotropic Direction", 2D) = "" {}
		_AnisoOffset ("Anisotropic Offset", Range(-1,1)) = -0.2
		_Angle ("Angle", Range(-1.5,  1.5)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Anisotropic fullforwardshadows
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_AnisoDir;
        };
		
		struct SurfaceAnisoOutput
		{
			float3 Albedo;
			float3 Normal;
			float3 Emission;
			float3 AnisoDirection;
			float Specular;
			float Gloss;
			float Alpha;
		};


        sampler2D _MainTex;
		sampler2D _AnisoDir;
		float4 _MainTint;
		float4 _SpecularColor;
		float _AnisoOffset;
		float _Specular;
		float _SpecPower;
		float _Angle;


        void surf (Input IN, inout SurfaceAnisoOutput o)
        {
		
			// Rotation Matrix
			float cosAngle = cos(_Angle);
			float sinAngle = sin(_Angle);
			float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);

			// Rotation consedering pivot
			float2 uv = mul(rot, IN.uv_AnisoDir);
			
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _MainTint;
			float3 anisoTex = UnpackNormal(tex2D(_AnisoDir, uv));
			o.AnisoDirection = anisoTex;
			o.Specular = _Specular;
			o.Gloss = _SpecPower;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
        }
		
		float4 LightingAnisotropic(SurfaceAnisoOutput s,
			float3 lightDir, float3 viewDir, float atten)
		{			
			float3 halfVector = normalize(normalize(lightDir) +	normalize(viewDir));
			float HdotA = dot(normalize(s.Normal + s.AnisoDirection), halfVector); 
			float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
        	
			float NdotL = saturate(dot(s.Normal, lightDir));
        	float3 diffuse = s.Albedo * _LightColor0.rgb * NdotL;
        	
			float3 spec = saturate(pow(aniso, s.Gloss * 128) * s.Specular) * _LightColor0.rgb * _SpecularColor.rgb;
			float4 c;
			c.rgb = (diffuse + spec) * atten;
			c.a = s.Alpha;
			return c;
		}
        ENDCG
    }
    FallBack "Diffuse"
}
