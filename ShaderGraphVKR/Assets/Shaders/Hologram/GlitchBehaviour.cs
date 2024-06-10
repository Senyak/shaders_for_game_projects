using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GlitchBehaviour : MonoBehaviour
{
    private Material material;

    private void Awake()
    {
        material = GetComponent<Renderer>().material;

        StartCoroutine(GlitchLoop());
    }

    private IEnumerator GlitchLoop()
    {
        while(true)
        {
            material.SetFloat("_GlitchStrength", 0.0f);
            yield return new WaitForSeconds(1.0f);

            material.SetFloat("_GlitchStrength", 0.3f);
            yield return new WaitForSeconds(0.25f);

            material.SetFloat("_GlitchStrength", 0.0f);
            yield return new WaitForSeconds(0.5f);

            material.SetFloat("_GlitchStrength", -0.2f);
            yield return new WaitForSeconds(0.15f);
        }
    }
}
