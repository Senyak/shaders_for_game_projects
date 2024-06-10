using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScanEffect : MonoBehaviour
{ 
    public Camera cam;
    public Material mat;
    private new bool enabled = false;
    public float scanSpeed = 1.0f;
    public float scanDist = 0.0f;
    public float scanWidth = 1.0f;
     
    private Vector3 scanCenter = Vector3.zero;
    private void Start()
    {
        cam.depthTextureMode = DepthTextureMode.Depth;
    }

     private void Update()
     {
         if (Input.GetMouseButtonDown(0))
         {
             Ray ray = cam.ScreenPointToRay(Input.mousePosition);
             RaycastHit hit;

             if (Physics.Raycast(ray, out hit))
             {
                 enabled = true;
                 scanDist = 0;
                 scanCenter = hit.point;
             }
         }
         else if (Input.GetMouseButtonDown(1))
         {
             enabled = false;
         }
         if (enabled)
         {
             scanDist += scanSpeed * Time.deltaTime;
         }
         
     }

     private void OnRenderImage(RenderTexture source, RenderTexture dest)
     {
         Matrix4x4 view = cam.worldToCameraMatrix;
         Matrix4x4 proj = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false);
         Matrix4x4 clipToWorld = Matrix4x4.Inverse(proj * view);
         
         mat.SetMatrix("_ClipToWorld", clipToWorld);
         mat.SetVector("_ScanCenter", scanCenter);
         mat.SetFloat("_ScanDist", scanDist);
         mat.SetFloat("_ScanWidth", scanWidth);
         
         Graphics.Blit(source, dest, mat);
     }
}
