Shader "Hidden/OldConsoles"
{
    Properties
    {
       
        _Color1 ("Color1", Color) = (0.0, 0.0, 0.0, 1.0) 
        _Color2 ("Color2", Color) = (0.23, 0.22, 0.22, 1.0) 
        _Color3 ("Color3", Color) = (0.42, 0.42, 0.42, 1.0) 
        _Color4 ("Color4", Color) = (0.74, 0.76, 0.65, 1.0) 
        _PixelSize ("Pixel Size", Range(0.001, 0.1)) = 1.0 
                
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            sampler2D _MainTex;
            float _PixelSize;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float4 _Color4;
 
            float4 frag(v2f_img i) : SV_Target
            {
                float posX = (int)(i.uv.x / _PixelSize) * _PixelSize;
                float posY = (int)(i.uv.y / _PixelSize) * _PixelSize;
                float4 mainColor = tex2D(_MainTex, float2(posX, posY));
                mainColor = LinearRgbToLuminance(mainColor);

                float level = mainColor.r <= 0.25;
                float level2 = mainColor.r > 0.25 && mainColor.r <= 0.5;
                float level3 = mainColor.r > 0.5 && mainColor.r <= 0.75;
                float level4 = (1 - level) && (1 - level2) && (1 - level3);

                mainColor = level * _Color1  + level2 * _Color2
                            + level3 * _Color3 + level4 * _Color4;
               
                return mainColor;
            }
 
            ENDCG
        }
    }
}
