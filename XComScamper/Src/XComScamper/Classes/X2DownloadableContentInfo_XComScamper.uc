class X2DownloadableContentInfo_XComScamper extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	local X2TacticalGameRuleset TacticalRulesCDO;

	TacticalRulesCDO = X2TacticalGameRuleset(class'XComEngine'.static.GetClassDefaultObject(class'X2TacticalGameRuleset'));
	TacticalRulesCDO.EventObserverClasses.AddItem(class'X2TacticalGameRuleset_XComScamperObserver');
}