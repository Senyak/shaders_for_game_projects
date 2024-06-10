Shader "Custom/Ch3.2"
{
    Properties
    {
        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NumbLevels ("CelShadingLevels", Range(-10.0, 10.0)) = 0.0
    }
    SubShader
    {
        Tags
        { 
			"RenderType"="Opaque" 
			"WrapMode" = "Clamp"
			"FilterMode" = "Point"
		}
        LOD 200

        CGPROGRAM
        #pragma surface surf Toon

        #pragma target 3.5

        sampler2D _MainTex;
		float _NumbLevels;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
        }
        
		float4 LightingToon(SurfaceOutput s, float3 lightDir, float atten)
		{
			float NdotL = saturate(dot (s.Normal, lightDir));
			float diffuse = NdotL;
			float cel = floor(diffuse * _NumbLevels)/(_NumbLevels - 0.5);
        	
			float4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * cel * atten;
			c.a = s.Alpha;
			return c;		
		}
        ENDCG
    }
    FallBack "Diffuse"
}
