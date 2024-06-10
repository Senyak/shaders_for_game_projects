using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[RequireComponent(typeof(MeshRenderer))]
public class DissolveDisVal : MonoBehaviour
{
    private const float MaxTreshhold = 1.01f;
    private const float MinTreshhold = -0.15f;
    private MeshRenderer _renderer;

    private Coroutine _show;

    private void Awake()
    {
        _renderer = GetComponent<MeshRenderer>();
    }

    void Update()
    {
        if (Input.GetKeyUp(KeyCode.F))
        {
            if(_show != null)
                StopCoroutine(_show);

            _show = StartCoroutine(Dissolve());

        }
        else if (Input.GetKeyUp(KeyCode.G))
        {
            if(_show != null)
                StopCoroutine(_show);

            _show = StartCoroutine(Appear());
            
        }
    }

    private IEnumerator Dissolve()
    {
        float treshold = -0.2f;
        while (treshold < MaxTreshhold)
        {
            treshold += Time.deltaTime/2;
            _renderer.material.SetFloat("_ThresholdValue", treshold);
            yield return null;
        }
    }
    
    IEnumerator Appear()
    {
        float treshold = 1.01f;
        while (treshold >= MinTreshhold)
        {
            treshold -= Time.deltaTime/2;
            _renderer.material.SetFloat("_ThresholdValue", treshold);
            yield return null;
        }
    }

}
