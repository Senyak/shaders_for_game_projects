using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthTexture : MonoBehaviour
{
    [SerializeField]
    DepthTextureMode depthTextureMode;
    private void Awake() {
        GetComponent<Camera>().depthTextureMode = depthTextureMode;
    }
    
    private void OnValidate()
    {
        SetCameraDepthTextureMode();
    }

   

    private void SetCameraDepthTextureMode()
    {
        GetComponent<Camera>().depthTextureMode = depthTextureMode;
    }

}
