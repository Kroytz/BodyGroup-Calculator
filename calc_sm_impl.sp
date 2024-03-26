
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ArrayList arrayBodyTrees;
ArrayList arrayBodies;

public void OnPluginStart()
{
    BodyGroupOnInit();
    RegConsoleCmd("bgc", Concmd_Test, "?");
}

public Action Concmd_Test(int client, int params)
{
    arrayBodies = new ArrayList(32);
    arrayBodies.PushString("collar");
    arrayBodies.PushString("watch");

    PrintToServer("BodyGroupIndex collar & watch: %d", BodyGroupCalculateBodyIndex(arrayBodyTrees, arrayBodies));

    arrayBodies.Clear();
    arrayBodies.PushString("sunglasses");
    arrayBodies.PushString("bracelet");

    PrintToServer("BodyGroupIndex sunglasses & bracelet: %d", BodyGroupCalculateBodyIndex(arrayBodyTrees, arrayBodies));
}

void BodyGroupOnInit()
{
    arrayBodyTrees = new ArrayList(64);
    
    /*
        [//BODYGROUP_1
                        "blank",
                        "collar",
                        "sunglasses",
        ],
        [//BODYGROUP_2
                        "blank",
                        "watch",
                        "bracelet",
                        "glove",
        ],
        [//BODYGROUP_3
                        "blank",
                        "hat",
                        "helmet",
                        "hair",
                        "bald",
                        "headphones",
        ],
    */
   
    StringMap smTemp = new StringMap(); // BODYGROUP_1
    smTemp.SetValue("blank", 0, true);
    smTemp.SetValue("collar", 1, true);
    smTemp.SetValue("sunglasses", 2, true);
    arrayBodyTrees.Push(smTemp);

    smTemp.Clear(); // BODYGROUP_2
    smTemp.SetValue("blank", 0, true);
    smTemp.SetValue("watch", 1, true);
    smTemp.SetValue("bracelet", 2, true);
    smTemp.SetValue("glove", 3, true);
    arrayBodyTrees.Push(smTemp);
}

int BodyGroupCalculateBodyIndex(ArrayList arrayBodyTree, ArrayList arrayBodiesWantToUse)
{
    /*
    local index = 0;
    for(local i=0;i<bodytree.len();i++)
    {
        local desiredbody_index = 0;
        local bodygroup_length = bodytree[i].len();
        if(i<bodies.len())
        {
            for(local j=0;j<bodygroup_length;j++)
            {
                if(bodytree[i][j] == bodies[i])
                {
                    desiredbody_index = j;
                    break;
                }
            }
        }
        local bitflag = 1;
        local lastbitflag = [1];
        for(local j=0;j<=i;j++)
        {
            if(j==0)
            {
                bitflag = 1;
                continue;
            }
            bitflag*=(0+bodytree[j-1].len() * lastbitflag[j-1]);
            lastbitflag.push(0+bitflag);
        }
        local indexadd = (bitflag * desiredbody_index);
        index += indexadd;
    }
    return index;
    */

    int index = 0;

    for (int i=0; i<arrayBodiesWantToUse.Length; i++)
    {
        int desiredBodyIndex = 0;
        char sKey[32]; arrayBodiesWantToUse.GetString(i, sKey, sizeof(sKey));

        StringMap smMap = arrayBodyTree.Get(i);
        if (!smMap.GetValue(sKey, desiredBodyIndex))
            desiredBodyIndex = 0;

        int bitFlag = 1;
        ArrayList arrayLastBitFlag = new ArrayList(32);

        for (int j=0; j<=i; j++)
        {
            if (j == 0)
            {
                bitFlag = 1;
                arrayLastBitFlag.Push(0 + bitFlag);
                continue;
            }

            smMap = arrayBodyTree.Get(j-1);
            bitFlag *= (0 + smMap.Size * arrayLastBitFlag.Get(j-1));
            arrayLastBitFlag.Push(0 + bitFlag);
        }

        delete arrayLastBitFlag;

        int indexAdd = (bitFlag * desiredBodyIndex);
        index += indexAdd;
    }

    return index;
}