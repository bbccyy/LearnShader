using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System;

public class DoubleFaceGUI : BaseGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;

        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});
        drawBlendMode();
        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});

        drawMainTex();
        drawMaskTex();
        drawNoiseTex();
    }

    public override void drawBlendMode()
    {
        MaterialProperty frontBM = FindProperty("_FrontBlendMode");
        EditorGUI.showMixedValue = frontBM.hasMixedValue;

        var frontMode = (BlendMode)frontBM.floatValue;
        var displayName = ChangeDisplayName(Styles.blendNames);
        EditorGUI.BeginChangeCheck();
        frontMode = (BlendMode)EditorGUILayout.Popup("Front Blending Mode", (int)frontMode, displayName);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Front Blending Mode");
            frontBM.floatValue = (float)frontMode;
            SetupBlendMode(target, (BlendingMode)frontBM.floatValue, "_FrontSrcBlend", "_FrontDstBlend");
        }

        MaterialProperty backBM = FindProperty("_BackBlendMode");
        EditorGUI.showMixedValue = backBM.hasMixedValue;

        var backMode = (BlendMode)backBM.floatValue;
        EditorGUI.BeginChangeCheck();
        backMode = (BlendMode)EditorGUILayout.Popup("Back Blending Mode", (int)backMode, displayName);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Back Blending Mode");
            backBM.floatValue = (float)backMode;
            SetupBlendMode(target, (BlendingMode)backBM.floatValue, "_BackSrcBlend", "_BackDstBlend");
        }
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
            editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo(RGB)"), mainTex);
            editor.TextureScaleOffsetProperty(mainTex);

            MaterialProperty alphaScale = FindProperty("_AlphaScale");
            editor.ShaderProperty(alphaScale, "Alpha Scale");

            MaterialProperty frontColor = FindProperty("_FrontColor");
            MaterialProperty backColor = FindProperty("_BackColor");
            editor.ShaderProperty(frontColor, "Front Color");
            editor.ShaderProperty(backColor, "Back Color");

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

            EditorGUI.indentLevel += 1;
            MaterialProperty speedU = FindProperty("_MaskUSpeed");
            MaterialProperty speedV = FindProperty("_MaskVSpeed");
            editor.ShaderProperty(speedU, "MaskSpeedU");
            editor.ShaderProperty(speedV, "MaskSpeedV");
            EditorGUI.indentLevel -= 2;
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
    //------------------------------------ Show Func -------------------------------------------//

}
