using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]

public class CameraEffect : MonoBehaviour
{
    public Material material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            Graphics.Blit(source, destination, material);
            // print("check material!!!!!!!!!!");
            Debug.Log("check material!!!!!!!!!!");
        }
        else
        {
            Graphics.Blit(source, destination);
            // print("something wrong!!!!!!!!!!");
            Debug.Log("something wrong!!!!!!!!!!");
        }
    }
}
