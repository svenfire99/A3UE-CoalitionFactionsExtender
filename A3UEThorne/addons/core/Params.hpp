// this file is used to add params for your extender
// see Params.hpp in the main Antistasi files for more examples

class Params
{
    class AllParams; // this line is aboslutely necessary
    class ExtenderParams; // this line is aboslutely necessary
    
    // class YourExtenderNameParams: ExtenderParams // this class is the base class for all of your params
    // {
    //     title = "[A3UE] Your Extender Name";
    //     values[] = {""};
    //     texts[] = {""};
    //     default = "";
    // };
    // class A3UE_YourExtenderName_ParamName: ExtenderParams // this is an actual parameter class
    // {
    //     title = $STR_A3UE_params_YourExtenderName_ParamName; // stringtable entry for your param title. If you don't want to use stringtable, you can also use a normal string here. If you do, you'll need to add your localizations to the Stringtable.xml file.
	// 	tooltip = $STR_A3UE_params_YourExtenderName_ParamName_desc; // stringtable entry for your param tooltip. If you don't want to use stringtable, you can also use a normal string here.
    //     values[] = {1,3,5,10,15,25,50,-1}; // parameter values
    //     texts[] = {"1", "3", "5", "10", "15", "25", "50", "Unlimited"}; // the associated texts for the param values that will be shown in the UI
    //     default = 3; // the default value
    //     lockInGame = 1; // 1 if the param should not be able to be changed in-game, 0 if it can be changed in-game
	// 	lockOnSave = 0; // 1 if the param should be locked / unchangeable after saving a game, 0 if it should not be locked
    // };
    // class YourExtenderNameSpacer : AllParams {}; // this is just an empty spacer after the end of your params to put some space in the UI between params from multiple extenders
};