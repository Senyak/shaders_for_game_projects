Shader "Hidden/Stroke"
{
    Properties 
	{
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _CameraDepthTexture;
        sampler2D _StrokeTex;
        sampler2D _GrayScaleTex;
		
        float4 _LightColor;
        float4 _ShadowColor;		
        float4 _MainTex_TexelSize;
        float4 _NoiseTex_TexelSize;
		
        float _HighThreshold;
        float _LowThreshold;
		
        float _BrightnessCorrection;
        float _BrightnessContrast;
        float _StrokeSize;
    ENDCG

    SubShader 
	{
        Cull Off 
		ZWrite Off 
		ZTest Always

        // оттенки серого //0
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            fixed4 frag(v2f_img i) : SV_Target 
			{
                return LinearRgbToLuminance(tex2D(_MainTex, i.uv));
            }

            ENDCG
        }
		
		//находим границы оператором Собеля //1
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float4 frag(v2f_img i) : SV_Target 
			{
                float Gx = 0.0f;
                float Gy = 0.0f;
				
                int3x3 Ker_x = 
				{
                    1, 0, -1,
                    2, 0, -2,
                    1, 0, -1
                };

                int3x3 Ker_y = 
				{
                     1,  2,  1,
                     0,  0,  0,
                    -1, -2, -1
                };

                for (int x = -1; x <= 1; x++) 
				{
                    for (int y = -1; y <= 1; y++) 
					{
                        float2 uv = i.uv + _MainTex_TexelSize * float2(x, y);
						
                        half tex = tex2D(_MainTex, uv).r;
						
                        Gx += Ker_x[x + 1][y + 1] * tex;
                        Gy += Ker_y[x + 1][y + 1] * tex;
                    }
                }
				//интенсивность изменения цвета 
                float magnitude = sqrt(Gx * Gx + Gy * Gy);
				//направление в котором произошло изменение цвета
                float theta = abs(atan2(Gy, Gx));

                return float4(magnitude, magnitude, magnitude, theta);
            }

            ENDCG
        }

		// определяем принадлежность границе в зависимости от значений соседних пикселей //2
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float4 frag(v2f_img i) : SV_Target 
			{
                float4 sobel = tex2D(_MainTex, i.uv);

                float magnitude = sobel.r;
                float theta = degrees(sobel.a);
				
				float4 res = 0.0f;
				//в зависимости от направления, в котором изменялся цвет
				//начинаем поиск границ рядом
                if ((0.0f <= theta && theta <= 45.0f) || (135.0f <= theta && theta <= 180.0f)) 
				{
                    float northMagnitude = tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(0, -1)).a;
                    float southMagnitude = tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(0, 1)).a;

                    res = (magnitude >= northMagnitude && magnitude >= southMagnitude) ? sobel : 0.0f;
					//если условие не выполнено, то текущий пиксель не является частью грани
					//значение sobel устанавливается в 0.0f, что означает отсутствие грани.
                } 
				else if (45.0f <= theta && theta <= 135.0f) 
				{
                    float westMagnitude = tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(-1, 0)).a;
                    float eastMagnitude = tex2D(_MainTex, i.uv + _MainTex_TexelSize * float2(1, 0)).a;

                    res = (magnitude >= westMagnitude && magnitude >= eastMagnitude) ? sobel : 0.0f;
                }

                return res;
            }

            ENDCG
        }
		
		//отсекаем ложные границы ниже минимального порога //3
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float4 frag(v2f_img i) : SV_Target 
			{
                float magnitude = tex2D(_MainTex, i.uv).r;

                float4 res = 0.0f;

                if (magnitude > _HighThreshold)
                    res = 8.0f;
                else if (magnitude > _LowThreshold)
                    res = 0.5f;

                return res;
            }

            ENDCG
        }

		// определяем какие границы являются продолжением настоящих //4
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float belongingToEdges(float2 uv) 
			{
                for (int x = -1; x <= 1; x++) 
				{
                    for (int y = -1; y <= 1; y++) 
					{
                        if (x == 0 && y == 0) 
							continue;

                        float2 neighboruv = uv + _MainTex_TexelSize * float2(x, y);
                        
                        half neighborStrength = tex2D(_MainTex, neighboruv).r;
                        if (neighborStrength == 1.0f) 
                            return 1.0f;
                    }
                }

                return 0.0f;
            }

            float4 frag(v2f_img i) : SV_Target 
			{
                float strength = tex2D(_MainTex, i.uv).r;

                float4 res = strength;

                if (strength == 0.5f) 
                    res = belongingToEdges(i.uv);

                return res;
            }

            ENDCG
        }
	
		//применяем шум к изображению //5
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata 
			{
	            float4 vertex : POSITION;
	            float2 uv : TEXCOORD0;
	        };

	        struct v2f 
			{
	            float2 uv : TEXCOORD0;
	            float4 vertex : SV_POSITION;
	            float4 screenPosition : TEXCOORD1;
	        };

	        v2f vert(appdata v) 
			{
	            v2f f;
	            f.vertex = UnityObjectToClipPos(v.vertex);
	            f.uv = v.uv;
	            f.screenPosition = ComputeScreenPos(f.vertex);
	            
	            return f;
	        }

            float4 frag(v2f i) : SV_Target 
			{
                float2 noiseCoord = i.screenPosition.xy / i.screenPosition.w;
                noiseCoord *= _ScreenParams.xy * _NoiseTex_TexelSize.xy;
                noiseCoord *= _StrokeSize;
                float noise = tex2Dlod(_NoiseTex, float4(noiseCoord.x, noiseCoord.y, 0, 0)).a; //texture, uv, lod
				
				//регулируем исходную тестуру по контрасту и световой коррекции
                
                float brightness = tex2D(_MainTex, i.uv).a;
				brightness = _BrightnessContrast * (brightness - 0.5f) + 0.5f;
                brightness = min(1.0f, max(0.0f, brightness));
                brightness = pow(brightness, 1.0f / _BrightnessCorrection);
                brightness = min(1.0f, max(0.0f, brightness));
                
                return brightness < noise ? 1.0f : 0.0f;
            }

            ENDCG
        }
        
		//совмещаем найденную границу и результат дизеринга //6
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float4 frag(v2f_img i) : SV_Target 
			{
                float edge = tex2D(_MainTex, i.uv).r;
                float4 stroke = tex2D(_StrokeTex, i.uv);
                float depth = 1 - Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);
                depth = min(1.0f, max(0.0f, depth));

				if (depth < 0.0001)
					stroke *= depth;

                float4 col =  1 - (edge + stroke);
                return col >= 1.0f ? _LightColor : _ShadowColor;
            }

            ENDCG
        }

		//раскрашиваем  //7
        Pass 
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            float4 frag(v2f_img i) : SV_Target 
			{
                float col = tex2D(_MainTex, i.uv).r;

                return col >= 1.0f ? _LightColor : _ShadowColor;
            }

            ENDCG
        }
        
    }
}
