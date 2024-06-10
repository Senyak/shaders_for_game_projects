using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class StrokeBehavoir : MonoBehaviour
{
    public Shader strokeShader;
    private Material strokeMaterial;
	
    public Color lightColor = Color.white;
    public Color shadowColor = Color.black;
	
    public Texture noiseTexture;

    [Range(0.01f, 1.0f)]
    public float highThreshold = 0.8f;

    [Range(0.01f, 1.0f)]
    public float lowThreshold = 0.1f;

    [Range(0.01f, 5.0f)]
    public float brightnessContrast = 0.9f;

    [Range(1.0f, 10.0f)]
    public float brightnessCorrection = 1.3f;

    [Range(0.01f, 1.0f)]
    public float strokeSize = 0.82f;


    void OnRenderImage(RenderTexture source, RenderTexture destination) 
	{
		strokeMaterial = new Material(strokeShader);
		
        strokeMaterial.SetColor("_LightColor", lightColor);
        strokeMaterial.SetColor("_ShadowColor", shadowColor);
        strokeMaterial.SetTexture("_NoiseTex", noiseTexture);
		
		strokeMaterial.SetFloat("_LowThreshold", lowThreshold);
		strokeMaterial.SetFloat("_HighThreshold", highThreshold);
		
        strokeMaterial.SetFloat("_BrightnessCorrection", brightnessCorrection);
        strokeMaterial.SetFloat("_BrightnessContrast", brightnessContrast);
        strokeMaterial.SetFloat("_StrokeSize", strokeSize);

        int width = source.width;
        int height = source.height;

		//изображение в оттенках серого
        RenderTexture grayScaleTex = RenderTexture.GetTemporary(width, height, 0, source.format);
        Graphics.Blit(source, grayScaleTex, strokeMaterial, 0);

		strokeMaterial.SetTexture("_GrayScaleTex", grayScaleTex);
        
		//находим изменение яркости оператором Собеля
		RenderTexture sobelTex = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		Graphics.Blit(grayScaleTex, sobelTex, strokeMaterial, 1);
		
		//смотрим на соседей
		RenderTexture belongToEdgeTex = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		Graphics.Blit(sobelTex, belongToEdgeTex, strokeMaterial, 2);
		RenderTexture.ReleaseTemporary(sobelTex);
		
		//отсекаем ложные границы
		RenderTexture doubleThresholdTex = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		Graphics.Blit(belongToEdgeTex, doubleThresholdTex, strokeMaterial, 3);		
		RenderTexture.ReleaseTemporary(belongToEdgeTex);
		
		//определяем продолжение настоящих границ
		RenderTexture hysteresisSource = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.ARGBFloat);
		Graphics.Blit(doubleThresholdTex, hysteresisSource, strokeMaterial, 4);
		RenderTexture.ReleaseTemporary(doubleThresholdTex);
		
		RenderTexture edgesTex = RenderTexture.GetTemporary(width, height, 0, source.format);
		Graphics.Blit(hysteresisSource, edgesTex);
		RenderTexture.ReleaseTemporary(hysteresisSource);				
		
		//применяем шум к исходному изображению
        RenderTexture ditheringTex = RenderTexture.GetTemporary(width, height, 0, source.format);
        Graphics.Blit(grayScaleTex, ditheringTex, strokeMaterial, 5);
        RenderTexture.ReleaseTemporary(grayScaleTex);

        strokeMaterial.SetTexture("_StrokeTex", ditheringTex);
		
		//объединяем результаты проходов
        RenderTexture mergeTex = RenderTexture.GetTemporary(width, height, 0, source.format);
        //Graphics.Blit(edgesTex, mergeTex, strokeMaterial, 6);
        Graphics.Blit(edgesTex, destination, strokeMaterial, 6);
        
		//раскрашиваем
        //Graphics.Blit(mergeTex, destination, strokeMaterial, 7);
        //Graphics.Blit(ditheringTex, destination);//, strokeMaterial, 7);
		
        RenderTexture.ReleaseTemporary(edgesTex);
        RenderTexture.ReleaseTemporary(ditheringTex);
        RenderTexture.ReleaseTemporary(mergeTex);

     }
    
}

