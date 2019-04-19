class X2Effect_ScamperPenalty extends X2Effect_PersistentStatChange config(Scamper);

var config bool EnableScamperPenalty;

event X2Effect_Persistent GetPersistantTemplate()
{
	return new class'X2Effect_ScamperPenalty';
}

static function VisualizeEffectRemoved(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_UpdateUI UIUpdate;
	local X2Action_Delay Delay;
	
	LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext()));
	LookAtAction.LookAtObject = ActionMetadata.StateObject_NewState;
	LookAtAction.UseTether = true;
	LookAtAction.LookAtDuration = 0.2f;
	LookAtAction.BlockUntilFinished = true;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(),, LookAtAction));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "Scamper penalty removed", '', eColor_Good,, 0.4, true);

	// Do not show the change instantly, but wait for flyout to animate in
	Delay = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(),, LookAtAction));
	Delay.Duration = 0.2;
	Delay.bIgnoreZipMode = true;

	UIUpdate = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(),, Delay));
	UIUpdate.UpdateType = EUIUT_UnitFlag_Buffs;
	UIUpdate.SpecificID = ActionMetadata.StateObject_NewState.ObjectID;
}

defaultproperties
{
	EffectName = "XComScamperPenalty"
	DuplicateResponse = eDupe_Refresh
	EffectRemovedVisualizationFn = VisualizeEffectRemoved;

	// Duration
	iNumTurns = 1
	bInfiniteDuration = false
	bRemoveWhenSourceDies = false // No source really
	bIgnorePlayerCheckOnTick = false
	WatchRule = eGameRule_PlayerTurnEnd // Allow full mobility during enemies' turn

	// Stat changes
	m_aStatChanges[0] = (StatType = eStat_Mobility, StatAmount = 0.6, ModOp = MODOP_Multiplication)

	// UI
	BuffCategory = ePerkBuff_Penalty
	FriendlyName = "Scamper penalty"
	FriendlyDescription = "Reduced mobility for scamper move"
	// IconImage TODO
	bDisplayInUI = true
}