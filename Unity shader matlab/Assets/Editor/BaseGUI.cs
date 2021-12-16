using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using System;

public class BaseGUI : ShaderGUI
{
    protected enum BlendingMode
    {
        Additive, AlphaBlend
    }

    protected enum CullMode
    {
        Off, Front, Back
    }

    protected static class Styles
    {
        public static readonly string[] blendNames = Enum.GetNames(typeof(BlendingMode));
        public static readonly string[] cullNames = Enum.GetNames(typeof(CullMode));
    }

    public Material target;
    public MaterialEditor editor;
    public MaterialProperty[] properties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.target = materialEditor.target as Material;
        this.editor = materialEditor;
        this.properties = properties;

        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});
        drawBlendMode();
        drawCullMode();
        drawZWrite();
        GUILayout.Box("", new GUILayoutOption[] {GUILayout.ExpandWidth(true), GUILayout.Height(2.0f)});

    }

    //------------------------------------ Utils -----------------------------------------------//
    protected MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }

    protected void RecordAction(string label)
    {
        editor.RegisterPropertyChangeUndo(label);
    }

    protected static string[] ChangeDisplayName(string[] blendNames)
    {
        string[] nameArray = new string[blendNames.Length];
        for (var i = 0; i < blendNames.Length; i++)
        {
            switch(blendNames[i])
            {
                case "Additive" :
                    nameArray[i] = "Additive(叠加)";
                    break;
                case "AlphaBlend" :
                    nameArray[i] = "AlphaBlend(混合透明)";
                    break;
            }
        }

        return nameArray;
    }

    static GUIContent staticLabel = new GUIContent();
    public static GUIContent MakeLabel(string text, string tooltip = null)
    {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    public static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        staticLabel.text = property.displayName;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }

    public bool isKeywordEnabled(string keyword)
    {
        return target.IsKeywordEnabled(keyword);
    }

    public void SetKeyWord(string keyword, bool state)
    {
        if (state)
        {
            foreach (Material m in editor.targets)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material m in editor.targets)
            {
                m.DisableKeyword(keyword);
            }
        }
    }
    //------------------------------------ Utils -----------------------------------------------//

    //------------------------------------ Show Func -------------------------------------------//
    // show blend mode
    public virtual void drawBlendMode()
    {
        MaterialProperty blendMode = FindProperty("_BlendMode");
        EditorGUI.showMixedValue = blendMode.hasMixedValue;

        var mode = (BlendMode)blendMode.floatValue;
        var displayName = ChangeDisplayName(Styles.blendNames);

        EditorGUI.BeginChangeCheck();
        mode = (BlendMode)EditorGUILayout.Popup("Blending Mode", (int)mode, displayName);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Blending Mode");
            blendMode.floatValue = (float)mode;
            SetupBlendMode(target, (BlendingMode)blendMode.floatValue);
        }
    }

    protected static void SetupBlendMode(Material material, BlendingMode blendMode)
    {
        switch(blendMode)
        {
            case BlendingMode.Additive:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)BlendMode.One);
                material.renderQueue = (int)RenderQueue.Transparent;
                break;
            case BlendingMode.AlphaBlend:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int)RenderQueue.Transparent;
                break;
        }
    }

    protected static void SetupBlendMode(Material material, BlendingMode blendMode, string srcBlendName, string dstBlendName)
    {
        switch(blendMode)
        {
            case BlendingMode.Additive:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt(srcBlendName, (int)BlendMode.SrcAlpha);
                material.SetInt(dstBlendName, (int)BlendMode.One);
                material.renderQueue = (int)RenderQueue.Transparent;
                break;
            case BlendingMode.AlphaBlend:
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInt(srcBlendName, (int)BlendMode.SrcAlpha);
                material.SetInt(dstBlendName, (int)BlendMode.OneMinusSrcAlpha);
                material.renderQueue = (int)RenderQueue.Transparent;
                break;
        }
    }

    // show cull mode
    public void drawCullMode()
    {
        MaterialProperty cullMode = FindProperty("_CullMode");
        EditorGUI.showMixedValue = cullMode.hasMixedValue;

        var mode = (CullMode) cullMode.floatValue;

        EditorGUI.BeginChangeCheck();
        mode = (CullMode)EditorGUILayout.Popup("Culling Mode", (int)mode, Styles.cullNames);

        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Culling Mode");
            cullMode.floatValue = (float)mode;
        }
        EditorGUI.showMixedValue = false;
    }

    // show zwrite
    public void drawZWrite()
    {
        MaterialProperty zWriteMode = FindProperty("_ZWrite");
        bool value = zWriteMode.floatValue == 0.0f;

        EditorGUI.BeginChangeCheck();
        editor.ShaderProperty(zWriteMode, "ZWrite OnOff");
        if (EditorGUI.EndChangeCheck())
        {
            zWriteMode.floatValue = value ? 1.0f : 0.0f;
        }
    }

    //------------------------------------ Show Func -------------------------------------------//

}
