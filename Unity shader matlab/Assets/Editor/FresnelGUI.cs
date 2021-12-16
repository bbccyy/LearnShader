using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System;

public class FresnelGUI : BaseGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        drawMainTex();
    }

    //------------------------------------ Show Func -------------------------------------------//

    // show main texture
    bool showMainTexture = false;
    void drawMainTex()
    {
        showMainTexture = EditorGUILayout.Foldout(showMainTexture, "Main Tex");
        if (showMainTexture)
        {
            EditorGUI.indentLevel += 1;
            MaterialProperty mainTex = FindProperty("_MainTex");
            editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo(RGB)"), mainTex, FindProperty("_TintColor"));
            editor.TextureScaleOffsetProperty(mainTex);

            MaterialProperty alphaScale = FindProperty("_AlphaScale");
            editor.ShaderProperty(alphaScale, "Alpha Scale");
            MaterialProperty colorPower = FindProperty("_ColorPower");
            editor.ShaderProperty(colorPower, "Color Power");
            EditorGUI.indentLevel += 1;
            MaterialProperty fresnelCol = FindProperty("_FresnelColor");
            MaterialProperty fresnelRange = FindProperty("_FresnelRange");
            MaterialProperty fresnelIntensity = FindProperty("_FresnelIntensity");
            editor.ShaderProperty(fresnelCol, "Fresnel Color");
            editor.ShaderProperty(fresnelRange, "Fresnel Range");
            editor.ShaderProperty(fresnelIntensity, "Fresnel Intensity");
            EditorGUI.indentLevel -= 2;
        }
    }
    //------------------------------------ Show Func -------------------------------------------//
}
