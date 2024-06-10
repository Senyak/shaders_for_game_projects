void CrackDepth_float(
                        float CrackDistance,
                        float CrackAmount,
                        UnityTexture2D Mask,
                        float3 ViewDirection,
                        float2 UV,
                        UnitySamplerState SS,
                        out float4 Out)
{
    float4 result = float4(1, 1, 1, 1);
    float maskValue = 0;
    float currentDist = 0;

    for(int i = 0; i < CrackAmount; i++)
    {
        currentDist -= CrackDistance * 0.01;
        float2 offset = float2((ViewDirection*currentDist).x, (ViewDirection*currentDist).y );
        maskValue = SAMPLE_TEXTURE2D_LOD(Mask, SS, (UV + offset),0).r;
        //maskValue = UNITY_SAMPLE_TEXTURE2D(Mask, SS, (UV + offset)).r;
        //maskValue = Mask.Sample(SS, (UV + offset)).r;
        result *= clamp(maskValue + (i/CrackAmount),0,1);
    }
    result.a = 1;
    Out = result;
}