Shader "Custom/BorderLight"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Bias("Bias", Range(-1,1)) = 0.25

    }
    SubShader
    {
		Tags
		{
		 "Queue" = "Transparent"
		 "IgnoreProjector" = "True"
		 "RenderType" = "Transparent"
		}
        LOD 200

        CGPROGRAM
        #pragma surface surf Lambert alpha:fade nolighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
			float3 worldNormal;
			float3 viewDir;
        };

		float _Bias;
        fixed4 _Color;
        
        void surf (Input i, inout SurfaceOutput o)
        {
			float4 c = tex2D(_MainTex, i.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			float VdotN = max(dot(normalize(i.viewDir), normalize(i.worldNormal)), 0.0);
			float alpha = ((1 - VdotN) * (1 - _Bias) + _Bias);

        	o.Alpha = alpha < 0 ? 0.0 : c.a * alpha;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
