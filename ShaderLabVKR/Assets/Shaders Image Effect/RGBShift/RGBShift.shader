Shader "Hidden/Chromatic"
{
     Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
 
        [Header(Red)]
        _RedX ("Offset X", Range(-0.5, 0.5)) = 0.0
        _RedY ("Offset Y", Range(-0.5, 0.5)) = 0.0
 
        [Header(Green)]
        _GreenX ("Offset X", Range(-0.5, 0.5)) = 0.0
        _GreenY ("Offset Y", Range(-0.5, 0.5)) = 0.0
 
        [Header(Blue)]
        _BlueX ("Offset X", Range(-0.5, 0.5)) = 0.0
        _BlueY ("Offset Y", Range(-0.5, 0.5)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
 
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
           
            #include "UnityCG.cginc"
 
            sampler2D _MainTex;
            float _RedX;
            float _RedY;
            float _GreenX;
            float _GreenY;
            float _BlueX;
            float _BlueY;
           
            float4 frag (v2f_img i) : SV_Target
            {
                float2 uvRed = i.uv + float2(_RedX, _RedY);
                float2 uvGreen = i.uv + float2(_GreenX, _GreenY);
                float2 uvBlue = i.uv + float2(_BlueX, _BlueY);

                float4 mainColor;
                mainColor.r = tex2D(_MainTex, uvRed).r;
                mainColor.g = tex2D(_MainTex, uvGreen).g;
                mainColor.b = tex2D(_MainTex, uvBlue).b;
                mainColor.a = 1.0;
 
                return mainColor;
            }
            ENDCG
        }
    }
}
