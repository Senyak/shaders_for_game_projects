using UnityEngine;

public class NormalsReplacementShader : MonoBehaviour
{
    [SerializeField]
    Shader normalsShader;

    private RenderTexture renderTexture;
    private new Camera camera;

    private void Start()
    {
        Camera mainCamera = GetComponent<Camera>();

        // Create a render texture matching the main camera's current dimensions.
        renderTexture = new RenderTexture(mainCamera.pixelWidth, mainCamera.pixelHeight, 24);
        // Surface the render texture as a global variable, available to all shaders.
        Shader.SetGlobalTexture("_CameraNormalsTexture", renderTexture);

        // Setup a copy of the camera to render the scene using the normals shader.
        GameObject copy = new GameObject("Normals camera");
        camera = copy.AddComponent<Camera>();
        camera.CopyFrom(mainCamera);
        camera.transform.SetParent(transform);
        camera.targetTexture = renderTexture;
        camera.SetReplacementShader(normalsShader, "RenderType");
        
        camera.depth = mainCamera.depth - 1;
    }
}