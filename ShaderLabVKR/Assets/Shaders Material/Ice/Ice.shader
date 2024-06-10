Shader "Hidden/Ice"
{
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Shininess ("Shininess", Range(0.1, 10)) = 1
        _SpecPower ("Specular Power", Range(0,30)) = 1
        _ReflectColor ("ReflectColor", Color) = (1,1,1,0.5)
        _ReflectStrength ("Reflection Strength", Range(0, 20)) = 1
        _RefractionTex ("Refraction", 2D) = "bump" {}
        _Cube ("Skybox Map", Cube) = "_Skybox" {}
        _LightStrength ("Light Strength", Range(0, 20)) = 0.1
        _FresnelPower ("Frenel Power", Float ) = 0.1
        _Transparent ("Transparency", Float ) = 0.1
        _RefractionStrength ("Refraction Strength", Range(-10, 10)) = 0
    }
    SubShader
    {
        Tags
        {
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "LightMode"="ForwardBase"
        }       
        
        GrabPass
        {
            "_GPTex"            
        }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            //ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _RefractionTex;
            float4 _RefractionTex_ST;
            sampler2D _GPTex;
            samplerCUBE _Cube;
            
            float4 _Color;
            float _Shininess;
		    float _SpecPower;
            float _ReflectStrength;
            float4 _ReflectColor;
            float _LightStrength;
            float _FresnelPower;
            float _Transparent;
            float _RefractionStrength;
            float4 _LightColor0;
            
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
                float4 posWS : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 bitangent : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.screenPos = o.vertex; //  ComputeScreenPos(o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                //корректируем пространство проекции
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                i.screenPos.y *= _ProjectionParams.x;
                
                float4 mainColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv, _MainTex)) * _Color;
                
                float2 normalTexPos = TRANSFORM_TEX(i.uv, _RefractionTex);
                float3 normalLocal = UnpackNormal(tex2D(_RefractionTex,normalTexPos));
                float3x3 tangentTransform = float3x3( i.tangent, i.bitangent, i.normal);
                float3 normalDir = normalize(mul( normalLocal, tangentTransform ));
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir = normalize(viewDir + lightDir);

                //диффузный
                float NdotL = max(0.0,dot(normalDir, lightDir) * _LightColor0);
                float3 diffuse = pow(max( 0.0, NdotL), mainColor.rgb);

                //отраженный
                float3 specularColor = float3(_Shininess,_Shininess,_Shininess);
                float3 specular = pow(max(0, dot(halfDir,normalDir)), _SpecPower) * specularColor;

                //эмиссия
                float3 viewReflectDir = reflect(-viewDir, normalDir);
                float4 cubeColor = texCUBE(_Cube,viewReflectDir);
                //half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, viewReflectDir);
                //half3 skyColor = DecodeHDR (skyData, unity_SpecCube0_HDR);
                
                //рассчитываем коэффициент Френеля, учитываая угол обзора, показатель преломления и
                //сглаживание изменения коэффициента отражения
                float4 frenel = pow(_FresnelPower,
                    lerp(-1, 0, pow(1.0 - max(0,dot(normalDir, viewDir)),
                                0.5 * dot(1.0, normalLocal.rgb) + 0.5)));
                float3 emission = lerp(mainColor.rgb, cubeColor.rgb, frenel) * _LightStrength * _ReflectStrength * _ReflectColor.rgb;

                //соединяем
                float2 sceneUVs = i.screenPos.xy * 0.5 + 0.5 + normalLocal.rg * (_RefractionStrength * 0.5);
                float4 sceneColor = tex2D(_GPTex, sceneUVs);
                float3 finalColor = diffuse + specular  + emission;
                return float4(lerp(sceneColor.rgb, finalColor, mainColor.a + _Transparent),1);
            }
            ENDCG
        }

        //UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
    FallBack "Diffuse"
    
}
