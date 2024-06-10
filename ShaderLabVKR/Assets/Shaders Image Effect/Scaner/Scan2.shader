Shader "Examples/ImageEffect/WorldScan"
{
    Properties
    {
    	[Hidden]_MainTex("Screen Texture", 2D) = "white" {}
        _ScanCenter("Start Point", Vector) = (0, 0, 0, 0)
        _ScanDist("Scan Distance", Float) = 0
        _ScanWidth("Scan Width", Float) = 1
        
    	_DetailTex("Detail Texture", 2D) = "white" {}
        _ScanColor("Scan Color", Color) = (1, 1, 1, 0)
		_DetailX("Detail X", float) = 30
		_DetailY("Detail X", float) = 40
		_DetailColor("Detail Color", Color) = (0.5, 0.5, 0.5, 0) 
    }
    SubShader
    {
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
            };

            sampler2D _CameraDepthTexture;
            sampler2D _MainTex;
			sampler2D _DetailTex;
            
            float3 _ScanCenter;
            float _ScanDist;
            float _ScanWidth;
            float4x4 _ClipToWorld;
            
			float _DetailX;
			float _DetailY;
			float4 _ScanColor;
			float4 _DetailColor;
             
            v2f vert (appdata v)
            {
                 v2f o;
                 o.vertex = UnityObjectToClipPos(v.vertex);
                 o.uv = v.uv;
                 return o;
            }

            float4 horizTex(float2 p)
			{
				return tex2D(_DetailTex, float2(p.x * _DetailX, p.y * _DetailY));
			}
             
            float4 frag (v2f i) : SV_Target
            {
                float depthTex = tex2D(_CameraDepthTexture, i.uv).r;
            	
                float4 pixelPosCS = float4(i.uv * 2.0f - 1.0f, depthTex, 1.0f);
                float4 pixelPosWS = mul(_ClipToWorld, pixelPosCS);
                float3 worldPos = pixelPosWS.xyz / pixelPosWS.w;

            	float fragDist = distance(worldPos, _ScanCenter);
                float4 scanColor = 0.0f;
            	
				float linearDepth = Linear01Depth(depthTex);
                if (fragDist < _ScanDist && fragDist > _ScanDist - _ScanWidth && linearDepth < 1)
                {
                    float diff = 1 - (_ScanDist - fragDist) / _ScanWidth;
                	float4 details = tex2D(_DetailTex, float2(i.uv.x * _DetailX, i.uv.y * _DetailY));
					scanColor = (_ScanColor + details * _DetailColor) * diff ;
                }
                
                float4 sceneColor = tex2D(_MainTex, i.uv);
                return sceneColor + scanColor;
                 
            }
            ENDCG
        }
    }
}
