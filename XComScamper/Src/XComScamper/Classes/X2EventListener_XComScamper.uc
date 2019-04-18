class X2EventListener_XComScamper extends X2EventListener config(Scamper);

var config bool GrantOnlyToRevealer;
var config bool DoNotTriggerOnLost;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListeners());

	return Templates;
}

static function X2EventListenerTemplate CreateListeners()
{
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'XComScamper');
	Template.AddEvent('ScamperEnd', OnScamperEnd);
	Template.RegisterInTactical = true;

	return Template;
}

static protected function EventListenerReturn OnScamperEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit InstigatorUnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComTacticalController TacticalController;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameState_Ability AbilityState;
	local XComGameState_AIGroup GroupState;
	local XComGameStateHistory History;
	local XComGameStateContext_XComScamper Context;

	GroupState = XComGameState_AIGroup(EventSource);
	History = `XCOMHISTORY;
	
	if (GroupState == none)
	{
		`RedScreen("XComScamper: Received ScamperEnd without XComGameState_AIGroup - aborting");
		return ELR_NoInterrupt;
	}

	if (
		GroupState.TeamName == eTeam_XCom ||
		GroupState.TeamName == eTeam_Resistance ||
		(default.DoNotTriggerOnLost && GroupState.TeamName == eTeam_TheLost)
	)
	{
		`log("Received ScamperEnd by " $ GroupState.TeamName $ " - ignoring",, 'XComScamper');
		return ELR_NoInterrupt;
	}
	
	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	TacticalRules = `TACTICALRULES;
	
	if (TacticalRules.GetCachedUnitActionPlayerRef() != TacticalController.ControllingPlayer)
	{
		`log("Received ScamperEnd but currently not XCom turn - ignoring",, 'XComScamper');
		return ELR_NoInterrupt;
	}

	foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', AbilityContext)
	{
		InstigatorUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

		if (InstigatorUnitState != none && InstigatorUnitState.ControllingPlayer == TacticalController.ControllingPlayer && AbilityState.IsAbilityInputTriggered())
		{
			if (AbilityContext.GetMovePathIndex(InstigatorUnitState.ObjectID) == INDEX_NONE)
			{
				`log("Received ScamperEnd but it wasn't caused by player issuing action that involved movement - ignoring",, 'XComScamper');
				return ELR_NoInterrupt;
			}
			else
			{
				// We confirmed that the last player activated ability was some sort of move
				break;
			}
		}
	}

	Context = XComGameStateContext_XComScamper(class'XComGameStateContext_XComScamper'.static.CreateXComGameStateContext());
	Context.RevealerUnitRef = AbilityContext.InputContext.SourceObject;

	TacticalRules.SubmitGameStateContext(Context);

	return ELR_NoInterrupt;
}