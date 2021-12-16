using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System;

public class ParticleMainGUI : BaseGUI
{
    public enum RenderingMode
    {
        Normal, UVAnimation, Dissolve, SequenceAnimation
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;

        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});
        drawBlendMode();
        drawRendingMode();
        drawCullMode();
        drawZWrite();
        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});

        drawMainTex();
        drawMaskTex();
        drawNoiseTex();
        if (isKeywordEnabled("_DISSOLVE"))
        {
            drawDissolveTex();
        }

        if (isKeywordEnabled("_SEQUENCE_ANIMATION"))
        {
            drawSequenceAnimation();
        }
    }

    //------------------------------------ Show Func -------------------------------------------//

    // show rending mode
    void drawRendingMode()
    {
        RenderingMode mode = RenderingMode.Normal;
        if (isKeywordEnabled("_DISSOLVE"))
        {
            mode = RenderingMode.Dissolve;
        }
        else if (isKeywordEnabled("_UV_ANIMATION"))
        {
            mode = RenderingMode.UVAnimation;
        }
        else if (isKeywordEnabled("_SEQUENCE_ANIMATION"))
        {
            mode = RenderingMode.SequenceAnimation;
        }

        EditorGUI.BeginChangeCheck();
        mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), mode);

        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Rendering Mode");
            SetKeyWord("_UV_ANIMATION", mode == RenderingMode.UVAnimation);
            SetKeyWord("_DISSOLVE", mode == RenderingMode.Dissolve);
            SetKeyWord("_SEQUENCE_ANIMATION", mode == RenderingMode.SequenceAnimation);
        }
    }

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

    // show dissolve texture
    bool showDissolveTexture = false;
    void drawDissolveTex()
    {
        showDissolveTexture = EditorGUILayout.Foldout(showDissolveTexture, "Dissolve Tex");
        if (showDissolveTexture)
        {
            EditorGUI.indentLevel += 1;
            MaterialProperty dissTex = FindProperty("_DissolveTex");
            editor.TexturePropertySingleLine(MakeLabel(dissTex, "Dissolve"), dissTex);
            editor.TextureScaleOffsetProperty(dissTex);

            EditorGUI.indentLevel += 1;
            MaterialProperty speedU = FindProperty("_DissolveUSpeed");
            MaterialProperty speedV = FindProperty("_DissolveVSpeed");
            editor.ShaderProperty(speedU, "DissolveSpeedU");
            editor.ShaderProperty(speedV, "DissolveSpeedV");

            EditorGUI.indentLevel += 1;
            MaterialProperty cutout = FindProperty("_DissolveCutout");
            MaterialProperty softedgeWidth = FindProperty("_SoftEdgeWidth");
            MaterialProperty edgeWidth = FindProperty("_EdgeWidth");
            MaterialProperty colorInside = FindProperty("_EdgeColorInside");
            MaterialProperty colorOutside = FindProperty("_EdgeColorOutSide");
            editor.ShaderProperty(cutout, "Dissolve Cutout");
            editor.ShaderProperty(edgeWidth, "Edge Width");
            editor.ShaderProperty(softedgeWidth, "Soft Edge Width");
            editor.ShaderProperty(colorInside, "Color - Edge Inside");
            editor.ShaderProperty(colorOutside, "Color - Edge Outside");

            EditorGUI.indentLevel -= 3;
        }
    }

    // show sequence animation
    bool showSequenceAnim = false;
    void drawSequenceAnimation()
    {
        showSequenceAnim = EditorGUILayout.Foldout(showSequenceAnim, "Sequence Anim");
        if (showSequenceAnim)
        {
            EditorGUI.indentLevel += 1;
            MaterialProperty horizontalLen = FindProperty("_HorizontalLen");
            MaterialProperty verticalLen = FindProperty("_VerticalLen");
            MaterialProperty sequenceSpeed = FindProperty("_SequenceSpeed");
            editor.ShaderProperty(horizontalLen, "Horizontal len");
            editor.ShaderProperty(verticalLen, "Vertical len");
            editor.ShaderProperty(sequenceSpeed, "Sequence Speed");

            EditorGUI.indentLevel -= 1;
        }
    }

    //------------------------------------ Show Func -------------------------------------------//
}
