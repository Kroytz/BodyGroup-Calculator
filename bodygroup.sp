#include <sourcemod>
#include <sdktools>
#include <smlib2>

char g_sPlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
#define BODYGROUP_TEMP_MAX 9
int g_iPlayerBodyGroup[MAXPLAYERS + 1][BODYGROUP_TEMP_MAX];

public Plugin myinfo =  
{
    name = "[CS:GO] BODYGROUP",
    author = "WACKOD & Kroytz",
    description = "FOR SERVER USE",
    version = "1.0",
    url = ""
}

public void OnPluginStart()
{
    Message.Init();
    Chat.SetPrefix("[{green}BodyGroup{default}]");

    RegConsoleCmd("sm_body", Command_JK);
}

public Action Command_JK(int client, int args)
{
    DisplayBodyGroupMenu(client);

    return Plugin_Handled;
}

void DisplayBodyGroupMenu(int client)
{
    if (!PlayerEx.IsExist(client))
    {
        Chat.ToOne(client, "你必须活着才可以使用换装系统！");
        return;
    }

    char m_ModelName[PLATFORM_MAX_PATH];
    GetEntPropString(client, Prop_Data, "m_ModelName", m_ModelName, PLATFORM_MAX_PATH);
    if (strcmp(g_sPlayerModel[client], m_ModelName, false) != 0)
    {
        FormatEx(g_sPlayerModel[client], PLATFORM_MAX_PATH, "%s", m_ModelName);

        for (int i=0; i<BODYGROUP_TEMP_MAX; i++)
            g_iPlayerBodyGroup[client][i] = 0;

        Chat.ToOne(client, "检测到您的模型发生变更, 已将所有设置重设...");
    }

    CStudioHdr pStudioHDR = CBaseAnimating_GetModelPtr(client);
    int iNumBodyGroups = pStudioHDR.GetNumBodyGroups();

    Menu menu = new Menu(Handler_MainMenu);
    menu.SetTitle("[BodyGroup]\n ");

    if (iNumBodyGroups <= 1)
    {
        menu.AddItem("", "你的模型不支持换装系统", ITEMDRAW_DISABLED);
        menu.AddItem("", "换个模型再来试试吧", ITEMDRAW_DISABLED);
    }
    else
    {
        char szBuffer[64];
        for (int i=1; i<=iNumBodyGroups; i++)
        {
            int style = (pStudioHDR.GetBodygroupCount(i-1) > 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
            Format(szBuffer, sizeof(szBuffer), "装扮位置 %d: [%d]", i-1, g_iPlayerBodyGroup[client][i-1]);
            menu.AddItem("", szBuffer, style);
        }
    }
    
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (!PlayerEx.IsExist(client))
            {
                Chat.ToOne(client, "你必须活着才可以使用换装系统！");
                return 0;
            }

            char m_ModelName[PLATFORM_MAX_PATH];
            GetEntPropString(client, Prop_Data, "m_ModelName", m_ModelName, PLATFORM_MAX_PATH);
            if (strcmp(g_sPlayerModel[client], m_ModelName, false) != 0)
            {
                FormatEx(g_sPlayerModel[client], PLATFORM_MAX_PATH, "%s", m_ModelName);

                for (int i=0; i<BODYGROUP_TEMP_MAX; i++)
                    g_iPlayerBodyGroup[client][i] = 0;

                Chat.ToOne(client, "检测到您的模型发生变更, 已将所有设置重设...");

                DisplayBodyGroupMenu(client);
                return 0;
            }

            CStudioHdr pStudioHDR = CBaseAnimating_GetModelPtr(client);
            int iBodies = pStudioHDR.GetBodygroupCount(itemNum);
            g_iPlayerBodyGroup[client][itemNum] ++;
            if (g_iPlayerBodyGroup[client][itemNum] >= iBodies)
                g_iPlayerBodyGroup[client][itemNum] = 0;

            int iBody = GetEntProp(client, Prop_Send, "m_nBody");
            pStudioHDR.SetBodygroup(iBody, itemNum, g_iPlayerBodyGroup[client][itemNum]);
            SetEntProp(client, Prop_Send, "m_nBody", iBody);

            Chat.ToOne(client, "已将您装扮位置 %d 的装扮设置为序号 %d. [%d]", itemNum, g_iPlayerBodyGroup[client][itemNum], iBody);
            DisplayBodyGroupMenu(client);
        }

        case MenuAction_End: delete menu;
    }

    return 0;
}

methodmap CStudioHdr
{
    public int GetNumBodyGroups()
    {
        int m_pStudioHdr = LoadFromAddress(view_as<Address>(this), NumberType_Int32);
        
        return LoadFromAddress(view_as<Address>(m_pStudioHdr + 232), NumberType_Int32);
    }
    
    public int GetBodygroupCount(int iGroup)
    {
        int m_pStudioHdr = LoadFromAddress(view_as<Address>(this), NumberType_Int32);
        
        // if(iGroup < this.GetNumBodyGroups())
        if(iGroup < LoadFromAddress(view_as<Address>(m_pStudioHdr + 232), NumberType_Int32))
        {
            int pbodypart = m_pStudioHdr + LoadFromAddress(view_as<Address>(m_pStudioHdr + 236), NumberType_Int32) + 16 * iGroup;
            
            // nummodels - 4
            return LoadFromAddress(view_as<Address>(pbodypart + 4), NumberType_Int32);
        }
        
        return 0;
    }
    
    public void SetBodygroup(int& body, int iGroup, int iValue)
    {
        int m_pStudioHdr = LoadFromAddress(view_as<Address>(this), NumberType_Int32);
        
        // if(iGroup < this.GetNumBodyGroups())
        if(iGroup < LoadFromAddress(view_as<Address>(m_pStudioHdr + 232), NumberType_Int32))
        {
            int pbodypart = m_pStudioHdr + LoadFromAddress(view_as<Address>(m_pStudioHdr + 236), NumberType_Int32) + 16 * iGroup;
            
            // nummodels - 4
            int nummodels = LoadFromAddress(view_as<Address>(pbodypart + 4), NumberType_Int32);
            if(nummodels > iValue)
            {
                int base = LoadFromAddress(view_as<Address>(pbodypart + 8), NumberType_Int32);
                
                body += (iValue - body / base % nummodels) * base;
            }
        }
    }
}

CStudioHdr CBaseAnimating_GetModelPtr(int iEnt)
{
    // OFF SET文件 https://github.com/qubka/Zombie-Plague/blob/67266c6b90d88180264745ccebff709531c722d0/gamedata/plugin.turret.txt#L8
    static int iStudioHdrOffs = 0;
    
    if(iStudioHdrOffs == 0)
    {
        iStudioHdrOffs = FindSendPropInfo("CBaseAnimating", "m_hLightingOrigin") + 68;
    }
    
    return view_as<CStudioHdr>(GetEntData(iEnt, iStudioHdrOffs));
}