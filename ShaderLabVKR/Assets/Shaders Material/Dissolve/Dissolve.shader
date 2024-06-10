Shader "Unlite/Dissolve"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
 
        _DissolveTex ("Dissolve texture", 2D) = "gray" {}
        _ThresholdValue ("Threshold", Range(-0.15, 1.01)) = 0.
        _EdgeWidth("Edge Threshold Width", float) = 1.0
        [HDR]_EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        
        _Shininess ("Shininess", Range(0.1, 100)) = 1.
        _SpecColor ("Specular color", color) = (1., 1., 1., 1.)
    }
 
    SubShader
    {
        Pass
        {
            Tags
            {
                "RenderType"="Transparent"
                "Queue"="Transparent"
                "LightMode"="ForwardBase"
            }
 
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             
            #include "UnityCG.cginc"

            struct appdata
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };
 
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 bitangent : TEXCOORD4;
            };
 
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
 
            float4 _LightColor0;
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            float _ThresholdValue;
            float _EdgeWidth;
            float4 _EdgeColor;
            
            float _Shininess;
            float4 _SpecColor;

            
            v2f vert(appdata v)
            {
                v2f o;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;
 
                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                float4 mainColor = tex2D(_MainTex, TRANSFORM_TEX(i.uv, _MainTex));
                
                float3 normalDir = normalize(i.normal);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir = normalize(viewDir + lightDir);
 
                //окружающий свет
                float4 ambient = float4(ShadeSH9(float4(i.normal,1)), 1); 
                
                //диффузный
                float4 NdotL = max(0.0, dot(normalDir, lightDir) * _LightColor0);
                float4 diffuse =  float4(pow(max( 0.0, NdotL), mainColor.rgb), 1.0);
 
                //отраженный
                float4 specular = pow(max(0, dot(halfDir,normalDir)), _Shininess) * _LightColor0 * _SpecColor;
                mainColor.rgb *= (diffuse + ambient + specular).rgb;

                float4 dissolveTex = tex2D(_DissolveTex, TRANSFORM_TEX(i.uv, _DissolveTex));
                clip(dissolveTex.r - _ThresholdValue);
                
                bool isNotEdge = dissolveTex.r  - _ThresholdValue > _EdgeWidth;
                mainColor = (1 - isNotEdge) * _EdgeColor + isNotEdge * mainColor;
                return mainColor;
            }
            ENDCG
        }
    }
}