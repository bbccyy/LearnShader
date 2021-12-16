using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System;

public class SpaceWarpGUI : BaseGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;

        drawMainTex();
        drawMaskTex();
        drawNoiseTex();
        drawShowMainTex();
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
            MaterialProperty warpStrength = FindProperty("_WarpStrength");
            editor.ShaderProperty(warpStrength, "Warp Strength");

            EditorGUI.indentLevel += 1;
            MaterialProperty speedU = FindProperty("_MainUSpeed");
            MaterialProperty speedV = FindProperty("_MainVSpeed");
            editor.ShaderProperty(speedU, "SpeedU");
            editor.ShaderProperty(speedV, "SpeedV");
            EditorGUI.indentLevel -= 2;
        }
    }

    // show mask texture
    bool showMaskTexture = false;
    void drawMaskTex()
    {
        showMaskTexture = EditorGUILayout.Foldout(showMaskTexture, "Mask Tex");
        if (showMaskTexture)
        {
            EditorGUI.indentLevel += 1;
            MaterialProperty maskTex = FindProperty("_MaskTex");
            editor.TexturePropertySingleLine(MakeLabel(maskTex, "Mask"), maskTex);
            editor.TextureScaleOffsetProperty(maskTex);
            EditorGUI.indentLevel -= 1;
        }
    }

    // show noise texture
    bool showNoiseTexture = false;
    void drawNoiseTex()
    {
        showNoiseTexture = EditorGUILayout.Foldout(showNoiseTexture, "Noise Tex");
        if (showNoiseTexture)
        {
            EditorGUI.indentLevel += 1;
            MaterialProperty noiseTex = FindProperty("_NoiseTex");
            editor.TexturePropertySingleLine(MakeLabel(noiseTex, "Noise"), noiseTex);
            editor.TextureScaleOffsetProperty(noiseTex);

            MaterialProperty noiseStrength = FindProperty("_NoiseStrength");
            editor.ShaderProperty(noiseStrength, "Noise Strength");
            EditorGUI.indentLevel += 1;
            MaterialProperty speedU = FindProperty("_NoiseUSpeed");
            MaterialProperty speedV = FindProperty("_NoiseVSpeed");
            editor.ShaderProperty(speedU, "NoiseSpeedU");
            editor.ShaderProperty(speedV, "NoiseSpeedV");
            EditorGUI.indentLevel -= 2;
        }
    }

    // show main tex
    bool showShowMainTex = false;
    void drawShowMainTex()
    {
        showShowMainTex = isKeywordEnabled("_MAIN_TEX_ON");
        showShowMainTex = EditorGUILayout.Toggle("IsShowMainTex", showShowMainTex, new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(20f)});
        SetKeyWord("_MAIN_TEX_ON", showShowMainTex);
    }
    //------------------------------------ Show Func -------------------------------------------//
}
