# La API de bots que ofrece el motor (volcado de primera mano)

Generado por `tools/datos/api_volcado.mjs` desde el volcado de `bots/FunLib/api_dump.lua` (variante del banco
`volcado_api`). Es lo que el propio Dota pone a disposición de los scripts de bots, leído desde dentro: manda sobre
la wiki de Valve (2016-2017, `docs/investigacion/2026-11-03-api-valve.md`) y sobre `docs/BOT_API_REFERENCE.md`.
Lo marcado **OHA** lo define un script de este repositorio (casi siempre `FunLib/aba_global_overrides.lua`, que
reemplaza llamadas de Valve): el bot propio no debe cargar esos reemplazos. Un método que existe no garantiza que
responda bien: eso se comprueba en partida.

## Funciones globales (156)

- `AddAvoidanceZone`
- `AddConditionalAvoidanceZone`
- `BenchRawPrint` — **OHA** (`bots/FunLib/aba_global_overrides.lua:74 (solo si el motor no la trae)`)
- `CMBanHero`
- `CMPickHero`
- `Clamp`
- `CreateHTTPRequest`
- `CreateRemoteHTTPRequest`
- `DebugDrawCircle`
- `DebugDrawLine`
- `DebugDrawText`
- `DebugPause`
- `DebuggerBreak`
- `DotaTime`
- `GameTime`
- `GeneratePath`
- `GetAllTrees`
- `GetAmountAlongLane`
- `GetAncient`
- `GetAvoidanceZones`
- `GetBarracks`
- `GetBot`
- `GetBotAbilityByHandle`
- `GetBotByHandle`
- `GetCMCaptain`
- `GetCMPhaseTimeRemaining`
- `GetCourier`
- `GetCourierForPlayer`
- `GetCourierState`
- `GetDefendLaneDesire`
- `GetDroppedItemList`
- `GetFarmLaneDesire`
- `GetGameMode`
- `GetGameState`
- `GetGameStateTimeRemaining`
- `GetGlyphCooldown`
- `GetHeightLevel`
- `GetHeroAssists`
- `GetHeroDeaths`
- `GetHeroKills`
- `GetHeroLastSeenInfo`
- `GetHeroLevel`
- `GetHeroPickState`
- `GetIncomingTeleports`
- `GetItemComponents`
- `GetItemCost`
- `GetItemStockCount`
- `GetLaneFrontAmount`
- `GetLaneFrontLocation`
- `GetLinearProjectileByHandle`
- `GetLinearProjectiles`
- `GetLocationAlongLane`
- `GetNeutralSpawners`
- `GetNumCouriers`
- `GetOpposingTeam`
- `GetOutpost`
- `GetPushLaneDesire`
- `GetRoamDesire`
- `GetRoamTarget`
- `GetRoshanDesire`
- `GetRoshanKillTime`
- `GetRuneSpawnLocation`
- `GetRuneStatus`
- `GetRuneTimeSinceSeen`
- `GetRuneType`
- `GetScriptDirectory` — **OHA** (`bots/Buff/Buff.lua:3 (solo si el motor no la trae)`)
- `GetSelectedHeroName`
- `GetShopLocation`
- `GetShrine`
- `GetShrineCooldown`
- `GetTeam`
- `GetTeamForPlayer`
- `GetTeamMember`
- `GetTeamPlayers` — **OHA** (`bots/FunLib/aba_global_overrides.lua:17`)
- `GetTimeOfDay`
- `GetTower`
- `GetTowerAttackTarget`
- `GetTreeLocation`
- `GetUnitList`
- `GetUnitPotentialValue`
- `GetUnitToLocationDistance`
- `GetUnitToLocationDistanceSqr`
- `GetUnitToUnitDistance` — **OHA** (`bots/FunLib/aba_global_overrides.lua:90`)
- `GetUnitToUnitDistanceSqr`
- `GetWorldBounds`
- `InstallCastCallback`
- `InstallChatCallback`
- `InstallCourierDeathCallback`
- `InstallDamageCallback`
- `InstallRoshanDeathCallback`
- `IsCMBannedHero`
- `IsCMPickedHero`
- `IsCourierAvailable`
- `IsFlyingCourier`
- `IsHeroAlive`
- `IsInCMBanPhase`
- `IsInCMPickPhase`
- `IsItemPurchasedFromSecretShop`
- `IsItemPurchasedFromSideShop`
- `IsLocationPassable`
- `IsLocationVisible`
- `IsPlayerBot`
- `IsPlayerInHeroSelectionControl`
- `IsRadiusVisible`
- `IsShrineHealing`
- `IsTeamPlayer`
- `LoadCustomize` — **OHA** (`bots/FunLib/custom_loader.lua:2`)
- `Max`
- `Min`
- `Msg`
- `PointToLineDistance`
- `QAngle`
- `RandomFloat` — **OHA** (`bots/FunLib/aba_global_overrides.lua:270`)
- `RandomFloatWrapper`
- `RandomInt`
- `RandomVector`
- `RealTime`
- `RemapValClamped`
- `RemoveAvoidanceZone`
- `RollPercentage`
- `Script_RandomFloat`
- `Script_RemapVal`
- `SelectHero`
- `SetCMCaptain`
- `Vector`
- `Warning`
- `assert`
- `collectgarbage`
- `dofile`
- `error`
- `gcinfo`
- `getfenv`
- `getmetatable`
- `ipairs`
- `load`
- `loadfile`
- `loadstring`
- `module`
- `newproxy`
- `next`
- `pairs`
- `pcall`
- `print` — **OHA** (`bots/FretBots/Debug.lua:10`)
- `printstack`
- `rawequal`
- `rawget`
- `rawset`
- `require`
- `select`
- `setfenv`
- `setmetatable`
- `tonumber`
- `tostring`
- `type`
- `unpack`
- `xpcall`

## Métodos de `CDOTA_Bot_Script` (220; visto en: heroe)

- `ActionImmediate_Buyback`
- `ActionImmediate_Chat`
- `ActionImmediate_Courier`
- `ActionImmediate_DisassembleItem`
- `ActionImmediate_Glyph`
- `ActionImmediate_LevelAbility`
- `ActionImmediate_Ping`
- `ActionImmediate_PurchaseItem`
- `ActionImmediate_SellItem`
- `ActionImmediate_SetItemCombineLock`
- `ActionImmediate_SwapItems` — **OHA** (`bots/FunLib/aba_global_overrides.lua:383`)
- `ActionPush_AttackMove`
- `ActionPush_AttackUnit`
- `ActionPush_Delay`
- `ActionPush_DropItem`
- `ActionPush_MoveDirectly`
- `ActionPush_MovePath`
- `ActionPush_MoveToLocation`
- `ActionPush_MoveToUnit`
- `ActionPush_PickUpItem`
- `ActionPush_PickUpRune`
- `ActionPush_UseAbility` — **OHA** (`bots/FunLib/aba_global_overrides.lua:314`)
- `ActionPush_UseAbilityOnEntity`
- `ActionPush_UseAbilityOnLocation`
- `ActionPush_UseAbilityOnTree`
- `ActionPush_UseShrine`
- `ActionQueue_AttackMove`
- `ActionQueue_AttackUnit`
- `ActionQueue_Delay`
- `ActionQueue_DropItem`
- `ActionQueue_MoveDirectly`
- `ActionQueue_MovePath`
- `ActionQueue_MoveToLocation`
- `ActionQueue_MoveToUnit`
- `ActionQueue_PickUpItem`
- `ActionQueue_PickUpRune`
- `ActionQueue_UseAbility`
- `ActionQueue_UseAbilityOnEntity`
- `ActionQueue_UseAbilityOnLocation`
- `ActionQueue_UseAbilityOnTree`
- `ActionQueue_UseShrine`
- `Action_AttackMove`
- `Action_AttackUnit`
- `Action_ClearActions`
- `Action_Delay`
- `Action_DropItem`
- `Action_MoveDirectly`
- `Action_MovePath`
- `Action_MoveToLocation`
- `Action_MoveToUnit`
- `Action_PickUpItem`
- `Action_PickUpRune`
- `Action_UseAbility` — **OHA** (`bots/FunLib/aba_global_overrides.lua:304`)
- `Action_UseAbilityOnEntity`
- `Action_UseAbilityOnLocation`
- `Action_UseAbilityOnTree`
- `Action_UseShrine`
- `CanBeSeen`
- `DistanceFromFountain`
- `DistanceFromSecretShop`
- `DistanceFromSideShop`
- `FindAoELocation`
- `FindItemSlot`
- `GetAbilityByName`
- `GetAbilityInSlot`
- `GetAbilityPoints`
- `GetAbilityTarget`
- `GetAcquisitionRange`
- `GetActiveMode`
- `GetActiveModeDesire`
- `GetActualIncomingDamage`
- `GetAnimActivity`
- `GetAnimCycle`
- `GetArmor`
- `GetAssignedLane`
- `GetAttackDamage`
- `GetAttackPoint`
- `GetAttackProjectileSpeed`
- `GetAttackRange` — **OHA** (`bots/FunLib/aba_global_overrides.lua:344`)
- `GetAttackSpeed`
- `GetAttackTarget` — **OHA** (`bots/FunLib/aba_global_overrides.lua:220`)
- `GetAttributeValue`
- `GetBaseDamage`
- `GetBaseDamageVariance`
- `GetBaseHealthRegen`
- `GetBaseManaRegen`
- `GetBaseMovementSpeed`
- `GetBoundingRadius`
- `GetBountyGoldMax`
- `GetBountyGoldMin`
- `GetBountyXP`
- `GetBuybackCooldown`
- `GetBuybackCost`
- `GetCourierValue`
- `GetCurrentActionType`
- `GetCurrentActiveAbility`
- `GetCurrentMovementSpeed`
- `GetCurrentVisionRange`
- `GetDayTimeVisionRange`
- `GetDenies`
- `GetDifficulty`
- `GetEstimatedDamageToTarget`
- `GetEvasion`
- `GetExtrapolatedLocation`
- `GetFacing`
- `GetGold`
- `GetGroundHeight`
- `GetHealth` — **OHA** (`bots/FunLib/aba_global_overrides.lua:412`)
- `GetHealthRegen`
- `GetHealthRegenPerStr`
- `GetIncomingTrackingProjectiles`
- `GetItemInSlot`
- `GetItemSlotType`
- `GetLastAttackTime`
- `GetLastHits`
- `GetLevel`
- `GetLocation` — **OHA** (`bots/FunLib/aba_global_overrides.lua:158`)
- `GetMagicResist` — **OHA** (`bots/FunLib/aba_global_overrides.lua:167`)
- `GetMana` — **OHA** (`bots/FunLib/aba_global_overrides.lua:455`)
- `GetManaRegen`
- `GetManaRegenPerInt`
- `GetMaxHealth` — **OHA** (`bots/FunLib/aba_global_overrides.lua:434`)
- `GetMaxMana` — **OHA** (`bots/FunLib/aba_global_overrides.lua:463`)
- `GetModifierAuxiliaryUnits`
- `GetModifierByName`
- `GetModifierList`
- `GetModifierName`
- `GetModifierRemainingDuration`
- `GetModifierStackCount`
- `GetMostRecentPing`
- `GetMovementDirectionStability`
- `GetNearbyBarracks`
- `GetNearbyCreeps` — **OHA** (`bots/FunLib/aba_global_overrides.lua:290`)
- `GetNearbyFillers`
- `GetNearbyHeroes` — **OHA** (`bots/FunLib/aba_global_overrides.lua:230`)
- `GetNearbyLaneCreeps` — **OHA** (`bots/FunLib/aba_global_overrides.lua:280`)
- `GetNearbyNeutralCreeps` — **OHA** (`bots/FunLib/aba_global_overrides.lua:275`)
- `GetNearbyShrines`
- `GetNearbyTowers` — **OHA** (`bots/FunLib/aba_global_overrides.lua:117`)
- `GetNearbyTrees`
- `GetNetWorth`
- `GetNextItemPurchaseValue`
- `GetNightTimeVisionRange`
- `GetOffensivePower`
- `GetPlayerID`
- `GetPrimaryAttribute`
- `GetQueuedActionType`
- `GetRawOffensivePower`
- `GetRemainingLifespan`
- `GetRespawnTime`
- `GetSecondsPerAttack`
- `GetSlowDuration`
- `GetSpellAmp`
- `GetStashValue`
- `GetStunDuration`
- `GetTalent`
- `GetTarget` — **OHA** (`bots/FunLib/aba_global_overrides.lua:334`)
- `GetTeam`
- `GetUnitName` — **OHA** (`bots/FunLib/aba_global_overrides.lua:295`)
- `GetUnitToLocationDistance` — **OHA** (`bots/FunLib/aba_global_overrides.lua:402`)
- `GetVelocity`
- `GetXPNeededToLevel`
- `HasBlink`
- `HasBuyback`
- `HasInvisibility`
- `HasMinistunOnAttack`
- `HasModifier` — **OHA** (`bots/FunLib/aba_global_overrides.lua:144`)
- `HasScepter`
- `HasSilence`
- `IsAlive`
- `IsAncientCreep`
- `IsAttackImmune` — **OHA** (`bots/FunLib/aba_global_overrides.lua:190`)
- `IsBlind`
- `IsBlockDisabled`
- `IsBot`
- `IsBuilding`
- `IsCastingAbility`
- `IsChanneling` — **OHA** (`bots/FunLib/aba_global_overrides.lua:210`)
- `IsCourier`
- `IsCreep`
- `IsDisarmed`
- `IsDominated`
- `IsEvadeDisabled`
- `IsFacingLocation`
- `IsFort`
- `IsHero`
- `IsHexed`
- `IsIllusion` — **OHA** (`bots/FunLib/aba_global_overrides.lua:127`)
- `IsInvisible`
- `IsInvulnerable` — **OHA** (`bots/FunLib/aba_global_overrides.lua:177`)
- `IsMagicImmune` — **OHA** (`bots/FunLib/aba_global_overrides.lua:240`)
- `IsMinion`
- `IsMuted`
- `IsNightmared`
- `IsNull`
- `IsRooted`
- `IsSilenced`
- `IsSpeciallyDeniable`
- `IsSpeciallyUndeniable`
- `IsStunned`
- `IsTower`
- `IsUnableToMiss`
- `IsUsingAbility` — **OHA** (`bots/FunLib/aba_global_overrides.lua:200`)
- `NumModifiers`
- `NumQueuedActions`
- `OriginalGetHealth` — **OHA** (`bots/FunLib/aba_global_overrides.lua:447`)
- `OriginalGetMaxHealth` — **OHA** (`bots/FunLib/aba_global_overrides.lua:450`)
- `SetNextItemPurchaseValue`
- `SetTarget`
- `TimeSinceDamagedByAnyHero`
- `TimeSinceDamagedByCreep`
- `TimeSinceDamagedByHero`
- `TimeSinceDamagedByPlayer`
- `TimeSinceDamagedByTower`
- `UsingItemBreaksInvisibility`
- `WasRecentlyDamagedByAnyHero` — **OHA** (`bots/FunLib/aba_global_overrides.lua:107`)
- `WasRecentlyDamagedByCreep`
- `WasRecentlyDamagedByHero`
- `WasRecentlyDamagedByPlayer`
- `WasRecentlyDamagedByTower`

## Métodos de `CDOTABaseAbility_BotScript` (50; visto en: habilidad)

- `CanAbilityBeUpgraded`
- `CanBeDisassembled`
- `GetAOERadius`
- `GetAbilityDamage`
- `GetAutoCastState`
- `GetBehavior`
- `GetCastPoint`
- `GetCastRange`
- `GetCaster`
- `GetChannelTime`
- `GetChannelledManaCostPerSecond`
- `GetCooldown`
- `GetCooldownTimeRemaining`
- `GetCurrentCharges`
- `GetDamageType`
- `GetDuration`
- `GetEstimatedDamageToTarget`
- `GetHeroLevelRequiredToUpgrade`
- `GetInitialCharges`
- `GetLevel`
- `GetManaCost`
- `GetMaxLevel`
- `GetName`
- `GetPowerTreadsStat`
- `GetSecondaryCharges`
- `GetSpecialValueFloat`
- `GetSpecialValueInt`
- `GetTargetFlags`
- `GetTargetTeam`
- `GetTargetType`
- `GetToggleState`
- `IsActivated`
- `IsChanneling`
- `IsCombineLocked`
- `IsCooldownReady`
- `IsFullyCastable`
- `IsHidden`
- `IsInAbilityPhase`
- `IsItem`
- `IsNull`
- `IsOwnersManaEnough`
- `IsPassive`
- `IsStealable`
- `IsStolen`
- `IsTalent`
- `IsToggle`
- `IsTrained`
- `IsUltimate`
- `ProcsMagicStick`
- `ToggleAutoCast`

(`objeto` usa la misma clase `CDOTABaseAbility_BotScript`.)

(`creep` usa la misma clase `CDOTA_Bot_Script`.)

(`edificio` usa la misma clase `CDOTA_Bot_Script`.)

(`mensajero` usa la misma clase `CDOTA_Bot_Script`.)

## Tablas globales

- `BotTeamCommander2`: `__self`
- `CDOTABaseAbility_BotScript`: `CanAbilityBeUpgraded`, `CanBeDisassembled`, `GetAOERadius`, `GetAbilityDamage`, `GetAutoCastState`, `GetBehavior`, `GetCastPoint`, `GetCastRange`, `GetCaster`, `GetChannelTime`, `GetChannelledManaCostPerSecond`, `GetCooldown`, `GetCooldownTimeRemaining`, `GetCurrentCharges`, `GetDamageType`, `GetDuration`, `GetEstimatedDamageToTarget`, `GetHeroLevelRequiredToUpgrade`, `GetInitialCharges`, `GetLevel`, `GetManaCost`, `GetMaxLevel`, `GetName`, `GetPowerTreadsStat`, `GetSecondaryCharges`, `GetSpecialValueFloat`, `GetSpecialValueInt`, `GetTargetFlags`, `GetTargetTeam`, `GetTargetType`, `GetToggleState`, `IsActivated`, `IsChanneling`, `IsCombineLocked`, `IsCooldownReady`, `IsFullyCastable`, `IsHidden`, `IsInAbilityPhase`, `IsItem`, `IsNull`, `IsOwnersManaEnough`, `IsPassive`, `IsStealable`, `IsStolen`, `IsTalent`, `IsToggle`, `IsTrained`, `IsUltimate`, `ProcsMagicStick`, `ToggleAutoCast`
- `CDOTA_Bot_Script`: `ActionImmediate_Buyback`, `ActionImmediate_Chat`, `ActionImmediate_Courier`, `ActionImmediate_DisassembleItem`, `ActionImmediate_Glyph`, `ActionImmediate_LevelAbility`, `ActionImmediate_Ping`, `ActionImmediate_PurchaseItem`, `ActionImmediate_SellItem`, `ActionImmediate_SetItemCombineLock`, `ActionImmediate_SwapItems`, `ActionPush_AttackMove`, `ActionPush_AttackUnit`, `ActionPush_Delay`, `ActionPush_DropItem`, `ActionPush_MoveDirectly`, `ActionPush_MovePath`, `ActionPush_MoveToLocation`, `ActionPush_MoveToUnit`, `ActionPush_PickUpItem`, `ActionPush_PickUpRune`, `ActionPush_UseAbility`, `ActionPush_UseAbilityOnEntity`, `ActionPush_UseAbilityOnLocation`, `ActionPush_UseAbilityOnTree`, `ActionPush_UseShrine`, `ActionQueue_AttackMove`, `ActionQueue_AttackUnit`, `ActionQueue_Delay`, `ActionQueue_DropItem`, `ActionQueue_MoveDirectly`, `ActionQueue_MovePath`, `ActionQueue_MoveToLocation`, `ActionQueue_MoveToUnit`, `ActionQueue_PickUpItem`, `ActionQueue_PickUpRune`, `ActionQueue_UseAbility`, `ActionQueue_UseAbilityOnEntity`, `ActionQueue_UseAbilityOnLocation`, `ActionQueue_UseAbilityOnTree`, `ActionQueue_UseShrine`, `Action_AttackMove`, `Action_AttackUnit`, `Action_ClearActions`, `Action_Delay`, `Action_DropItem`, `Action_MoveDirectly`, `Action_MovePath`, `Action_MoveToLocation`, `Action_MoveToUnit`, `Action_PickUpItem`, `Action_PickUpRune`, `Action_UseAbility`, `Action_UseAbilityOnEntity`, `Action_UseAbilityOnLocation`, `Action_UseAbilityOnTree`, `Action_UseShrine`, `CanBeSeen`, `DistanceFromFountain`, `DistanceFromSecretShop`, `DistanceFromSideShop`, `FindAoELocation`, `FindItemSlot`, `GetAbilityByName`, `GetAbilityInSlot`, `GetAbilityPoints`, `GetAbilityTarget`, `GetAcquisitionRange`, `GetActiveMode`, `GetActiveModeDesire`, `GetActualIncomingDamage`, `GetAnimActivity`, `GetAnimCycle`, `GetArmor`, `GetAssignedLane`, `GetAttackDamage`, `GetAttackPoint`, `GetAttackProjectileSpeed`, `GetAttackRange`, `GetAttackSpeed`, `GetAttackTarget`, `GetAttributeValue`, `GetBaseDamage`, `GetBaseDamageVariance`, `GetBaseHealthRegen`, `GetBaseManaRegen`, `GetBaseMovementSpeed`, `GetBoundingRadius`, `GetBountyGoldMax`, `GetBountyGoldMin`, `GetBountyXP`, `GetBuybackCooldown`, `GetBuybackCost`, `GetCourierValue`, `GetCurrentActionType`, `GetCurrentActiveAbility`, `GetCurrentMovementSpeed`, `GetCurrentVisionRange`, `GetDayTimeVisionRange`, `GetDenies`, `GetDifficulty`, `GetEstimatedDamageToTarget`, `GetEvasion`, `GetExtrapolatedLocation`, `GetFacing`, `GetGold`, `GetGroundHeight`, `GetHealth`, `GetHealthRegen`, `GetHealthRegenPerStr`, `GetIncomingTrackingProjectiles`, `GetItemInSlot`, `GetItemSlotType`, `GetLastAttackTime`, `GetLastHits`, `GetLevel`, `GetLocation`, `GetMagicResist`, `GetMana`, `GetManaRegen`, `GetManaRegenPerInt`, `GetMaxHealth`, `GetMaxMana`, `GetModifierAuxiliaryUnits`, `GetModifierByName`, `GetModifierList`, `GetModifierName`, `GetModifierRemainingDuration`, `GetModifierStackCount`, `GetMostRecentPing`, `GetMovementDirectionStability`, `GetNearbyBarracks`, `GetNearbyCreeps`, `GetNearbyFillers`, `GetNearbyHeroes`, `GetNearbyLaneCreeps`, `GetNearbyNeutralCreeps`, `GetNearbyShrines`, `GetNearbyTowers`, `GetNearbyTrees`, `GetNetWorth`, `GetNextItemPurchaseValue`, `GetNightTimeVisionRange`, `GetOffensivePower`, `GetPlayerID`, `GetPrimaryAttribute`, `GetQueuedActionType`, `GetRawOffensivePower`, `GetRemainingLifespan`, `GetRespawnTime`, `GetSecondsPerAttack`, `GetSlowDuration`, `GetSpellAmp`, `GetStashValue`, `GetStunDuration`, `GetTalent`, `GetTarget`, `GetTeam`, `GetUnitName`, `GetUnitToLocationDistance`, `GetVelocity`, `GetXPNeededToLevel`, `HasBlink`, `HasBuyback`, `HasInvisibility`, `HasMinistunOnAttack`, `HasModifier`, `HasScepter`, `HasSilence`, `IsAlive`, `IsAncientCreep`, `IsAttackImmune`, `IsBlind`, `IsBlockDisabled`, `IsBot`, `IsBuilding`, `IsCastingAbility`, `IsChanneling`, `IsCourier`, `IsCreep`, `IsDisarmed`, `IsDominated`, `IsEvadeDisabled`, `IsFacingLocation`, `IsFort`, `IsHero`, `IsHexed`, `IsIllusion`, `IsInvisible`, `IsInvulnerable`, `IsMagicImmune`, `IsMinion`, `IsMuted`, `IsNightmared`, `IsNull`, `IsRooted`, `IsSilenced`, `IsSpeciallyDeniable`, `IsSpeciallyUndeniable`, `IsStunned`, `IsTower`, `IsUnableToMiss`, `IsUsingAbility`, `NumModifiers`, `NumQueuedActions`, `OriginalGetHealth`, `OriginalGetMaxHealth`, `SetNextItemPurchaseValue`, `SetTarget`, `TimeSinceDamagedByAnyHero`, `TimeSinceDamagedByCreep`, `TimeSinceDamagedByHero`, `TimeSinceDamagedByPlayer`, `TimeSinceDamagedByTower`, `UsingItemBreaksInvisibility`, `WasRecentlyDamagedByAnyHero`, `WasRecentlyDamagedByCreep`, `WasRecentlyDamagedByHero`, `WasRecentlyDamagedByPlayer`, `WasRecentlyDamagedByTower`
- `CDOTA_TeamCommander`: `IsNull`
- `HeroSelectionScriptScope`: `AlignLanesBasedOnRoles`, `GetBotNames`, `GetHumanChatHero`, `GetSelectedHumanHero`, `HandleLocaleSetting`, `OneVsOneLogic`, `SelectHeroChatCallback`, `Think`, `UpdateLaneAssignments`
- `TeamDesiresScriptScope`: `TeamThink`
- `bit`: `arshift`, `band`, `bnot`, `bor`, `bswap`, `bxor`, `lshift`, `rol`, `ror`, `rshift`, `tobit`, `tohex`
- `coroutine`: `create`, `isyieldable`, `resume`, `running`, `status`, `wrap`, `yield`
- `g_reloadState`: `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `C:\Program`, `_G`, `bit`, `coroutine`, `math`, `package`, `string`, `table`
- `math`: `abs`, `acos`, `asin`, `atan`, `atan2`, `ceil`, `cos`, `cosh`, `deg`, `exp`, `floor`, `fmod`, `frexp`, `huge`, `ldexp`, `log`, `log10`, `max`, `min`, `mod`, `modf`, `pi`, `pow`, `rad`, `random`, `randomseed`, `sin`, `sinh`, `sqrt`, `tan`, `tanh`
- `package`: `config`, `cpath`, `loaded`, `loaders`, `path`, `preload`, `searchpath`, `seeall`
- `string`: `byte`, `char`, `dump`, `find`, `format`, `gfind`, `gmatch`, `gsub`, `len`, `lower`, `match`, `rep`, `reverse`, `sub`, `upper`
- `table`: `concat`, `foreach`, `foreachi`, `getn`, `insert`, `maxn`, `move`, `remove`, `sort`

## Constantes (358)

| Nombre | Valor |
|---|---|
| `ABILITY_BEHAVIOR_AOE` | 32 |
| `ABILITY_BEHAVIOR_ATTACK` | 131072 |
| `ABILITY_BEHAVIOR_AURA` | 65536 |
| `ABILITY_BEHAVIOR_AUTOCAST` | 4096 |
| `ABILITY_BEHAVIOR_CHANNELLED` | 128 |
| `ABILITY_BEHAVIOR_DIRECTIONAL` | 1024 |
| `ABILITY_BEHAVIOR_DONT_ALERT_TARGET` | 16777216 |
| `ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL` | 536870912 |
| `ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT` | 8388608 |
| `ABILITY_BEHAVIOR_DONT_RESUME_ATTACK` | 33554432 |
| `ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT` | 262144 |
| `ABILITY_BEHAVIOR_HIDDEN` | 1 |
| `ABILITY_BEHAVIOR_IGNORE_BACKSWING` | 134217728 |
| `ABILITY_BEHAVIOR_IGNORE_CHANNEL` | 4194304 |
| `ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE` | 2097152 |
| `ABILITY_BEHAVIOR_IMMEDIATE` | 2048 |
| `ABILITY_BEHAVIOR_ITEM` | 256 |
| `ABILITY_BEHAVIOR_LAST_RESORT_POINT` | -2147483648 |
| `ABILITY_BEHAVIOR_NONE` | 0 |
| `ABILITY_BEHAVIOR_NORMAL_WHEN_STOLEN` | 67108864 |
| `ABILITY_BEHAVIOR_NOT_LEARNABLE` | 64 |
| `ABILITY_BEHAVIOR_NO_TARGET` | 4 |
| `ABILITY_BEHAVIOR_OPTIONAL_NO_TARGET` | 32768 |
| `ABILITY_BEHAVIOR_OPTIONAL_POINT` | 16384 |
| `ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET` | 8192 |
| `ABILITY_BEHAVIOR_PASSIVE` | 2 |
| `ABILITY_BEHAVIOR_POINT` | 16 |
| `ABILITY_BEHAVIOR_ROOT_DISABLES` | 524288 |
| `ABILITY_BEHAVIOR_RUNE_TARGET` | 268435456 |
| `ABILITY_BEHAVIOR_TOGGLE` | 512 |
| `ABILITY_BEHAVIOR_UNIT_TARGET` | 8 |
| `ABILITY_BEHAVIOR_UNRESTRICTED` | 1048576 |
| `ABILITY_BEHAVIOR_VECTOR_TARGETING` | 1073741824 |
| `ABILITY_TARGET_FLAG_CHECK_DISABLE_HELP` | 65536 |
| `ABILITY_TARGET_FLAG_DEAD` | 8 |
| `ABILITY_TARGET_FLAG_FOW_VISIBLE` | 128 |
| `ABILITY_TARGET_FLAG_INVULNERABLE` | 64 |
| `ABILITY_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES` | 16 |
| `ABILITY_TARGET_FLAG_MANA_ONLY` | 32768 |
| `ABILITY_TARGET_FLAG_MELEE_ONLY` | 4 |
| `ABILITY_TARGET_FLAG_NONE` | 0 |
| `ABILITY_TARGET_FLAG_NOT_ANCIENTS` | 512 |
| `ABILITY_TARGET_FLAG_NOT_ATTACK_IMMUNE` | 16384 |
| `ABILITY_TARGET_FLAG_NOT_CREEP_HERO` | 131072 |
| `ABILITY_TARGET_FLAG_NOT_DOMINATED` | 2048 |
| `ABILITY_TARGET_FLAG_NOT_ILLUSIONS` | 8192 |
| `ABILITY_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES` | 32 |
| `ABILITY_TARGET_FLAG_NOT_NIGHTMARED` | 524288 |
| `ABILITY_TARGET_FLAG_NOT_SUMMONED` | 4096 |
| `ABILITY_TARGET_FLAG_NO_INVIS` | 256 |
| `ABILITY_TARGET_FLAG_OUT_OF_WORLD` | 262144 |
| `ABILITY_TARGET_FLAG_PLAYER_CONTROLLED` | 1024 |
| `ABILITY_TARGET_FLAG_PREFER_ENEMIES` | 1048576 |
| `ABILITY_TARGET_FLAG_RANGED_ONLY` | 2 |
| `ABILITY_TARGET_TEAM_BOTH` | 3 |
| `ABILITY_TARGET_TEAM_ENEMY` | 2 |
| `ABILITY_TARGET_TEAM_FRIENDLY` | 1 |
| `ABILITY_TARGET_TEAM_NONE` | 0 |
| `ABILITY_TARGET_TYPE_ALL` | 55 |
| `ABILITY_TARGET_TYPE_BASIC` | 18 |
| `ABILITY_TARGET_TYPE_BUILDING` | 4 |
| `ABILITY_TARGET_TYPE_COURIER` | 16 |
| `ABILITY_TARGET_TYPE_CREEP` | 2 |
| `ABILITY_TARGET_TYPE_HERO` | 1 |
| `ABILITY_TARGET_TYPE_NONE` | 0 |
| `ABILITY_TARGET_TYPE_OTHER` | 32 |
| `ABILITY_TARGET_TYPE_TREE` | 64 |
| `ACTIVITY_ATTACK` | 1503 |
| `ACTIVITY_ATTACK2` | 1504 |
| `ACTIVITY_ATTACK_EVENT` | 1505 |
| `ACTIVITY_CAPTURE` | 1533 |
| `ACTIVITY_CAST_ABILITY_1` | 1510 |
| `ACTIVITY_CAST_ABILITY_2` | 1511 |
| `ACTIVITY_CAST_ABILITY_3` | 1512 |
| `ACTIVITY_CAST_ABILITY_4` | 1513 |
| `ACTIVITY_CAST_ABILITY_5` | 1514 |
| `ACTIVITY_CAST_ABILITY_6` | 1515 |
| `ACTIVITY_CHANNEL_ABILITY_1` | 1520 |
| `ACTIVITY_CHANNEL_ABILITY_2` | 1521 |
| `ACTIVITY_CHANNEL_ABILITY_3` | 1522 |
| `ACTIVITY_CHANNEL_ABILITY_4` | 1523 |
| `ACTIVITY_CHANNEL_ABILITY_5` | 1524 |
| `ACTIVITY_CHANNEL_ABILITY_6` | 1525 |
| `ACTIVITY_CHANNEL_END_ABILITY_1` | 1526 |
| `ACTIVITY_CHANNEL_END_ABILITY_2` | 1527 |
| `ACTIVITY_CHANNEL_END_ABILITY_3` | 1528 |
| `ACTIVITY_CHANNEL_END_ABILITY_4` | 1529 |
| `ACTIVITY_CHANNEL_END_ABILITY_5` | 1530 |
| `ACTIVITY_CHANNEL_END_ABILITY_6` | 1531 |
| `ACTIVITY_CONSTANT_LAYER` | 1532 |
| `ACTIVITY_DIE` | 1506 |
| `ACTIVITY_DISABLED` | 1509 |
| `ACTIVITY_FLAIL` | 1508 |
| `ACTIVITY_FLINCH` | 1507 |
| `ACTIVITY_IDLE` | 1500 |
| `ACTIVITY_IDLE_RARE` | 1501 |
| `ACTIVITY_KILLTAUNT` | 1535 |
| `ACTIVITY_OVERRIDE_ABILITY_1` | 1516 |
| `ACTIVITY_OVERRIDE_ABILITY_2` | 1517 |
| `ACTIVITY_OVERRIDE_ABILITY_3` | 1518 |
| `ACTIVITY_OVERRIDE_ABILITY_4` | 1519 |
| `ACTIVITY_RUN` | 1502 |
| `ACTIVITY_SPAWN` | 1534 |
| `ACTIVITY_TAUNT` | 1536 |
| `ATTRIBUTE_AGILITY` | 1 |
| `ATTRIBUTE_INTELLECT` | 2 |
| `ATTRIBUTE_INVALID` | -1 |
| `ATTRIBUTE_STRENGTH` | 0 |
| `BARRACKS_BOT_MELEE` | 4 |
| `BARRACKS_BOT_RANGED` | 5 |
| `BARRACKS_MID_MELEE` | 2 |
| `BARRACKS_MID_RANGED` | 3 |
| `BARRACKS_TOP_MELEE` | 0 |
| `BARRACKS_TOP_RANGED` | 1 |
| `BOT_ACTION_DESIRE_ABSOLUTE` | 1 |
| `BOT_ACTION_DESIRE_HIGH` | 0.75 |
| `BOT_ACTION_DESIRE_LOW` | 0.25 |
| `BOT_ACTION_DESIRE_MODERATE` | 0.5 |
| `BOT_ACTION_DESIRE_NONE` | 0 |
| `BOT_ACTION_DESIRE_VERYHIGH` | 0.89999997615814 |
| `BOT_ACTION_DESIRE_VERYLOW` | 0.10000000149012 |
| `BOT_ACTION_TYPE_ATTACK` | 4 |
| `BOT_ACTION_TYPE_ATTACKMOVE` | 5 |
| `BOT_ACTION_TYPE_DELAY` | 11 |
| `BOT_ACTION_TYPE_DROP_ITEM` | 9 |
| `BOT_ACTION_TYPE_IDLE` | 1 |
| `BOT_ACTION_TYPE_MOVE_TO` | 2 |
| `BOT_ACTION_TYPE_MOVE_TO_DIRECTLY` | 3 |
| `BOT_ACTION_TYPE_NONE` | 0 |
| `BOT_ACTION_TYPE_PICK_UP_ITEM` | 8 |
| `BOT_ACTION_TYPE_PICK_UP_RUNE` | 7 |
| `BOT_ACTION_TYPE_SHRINE` | 10 |
| `BOT_ACTION_TYPE_USE_ABILITY` | 6 |
| `BOT_MODE_ASSEMBLE` | 14 |
| `BOT_MODE_ASSEMBLE_WITH_HUMANS` | 15 |
| `BOT_MODE_ATTACK` | 2 |
| `BOT_MODE_DEFEND_ALLY` | 18 |
| `BOT_MODE_DEFEND_TOWER_BOT` | 13 |
| `BOT_MODE_DEFEND_TOWER_MID` | 12 |
| `BOT_MODE_DEFEND_TOWER_TOP` | 11 |
| `BOT_MODE_DESIRE_ABSOLUTE` | 1 |
| `BOT_MODE_DESIRE_HIGH` | 0.75 |
| `BOT_MODE_DESIRE_LOW` | 0.25 |
| `BOT_MODE_DESIRE_MODERATE` | 0.5 |
| `BOT_MODE_DESIRE_NONE` | 0 |
| `BOT_MODE_DESIRE_VERYHIGH` | 0.89999997615814 |
| `BOT_MODE_DESIRE_VERYLOW` | 0.10000000149012 |
| `BOT_MODE_EVASIVE_MANEUVERS` | 19 |
| `BOT_MODE_FARM` | 17 |
| `BOT_MODE_ITEM` | 21 |
| `BOT_MODE_LANING` | 1 |
| `BOT_MODE_NONE` | 0 |
| `BOT_MODE_OUTPOST` | 26 |
| `BOT_MODE_PUSH_TOWER_BOT` | 10 |
| `BOT_MODE_PUSH_TOWER_MID` | 9 |
| `BOT_MODE_PUSH_TOWER_TOP` | 8 |
| `BOT_MODE_RETREAT` | 4 |
| `BOT_MODE_ROAM` | 3 |
| `BOT_MODE_ROSHAN` | 20 |
| `BOT_MODE_RUNE` | 7 |
| `BOT_MODE_SECRET_SHOP` | 5 |
| `BOT_MODE_SIDE_SHOP` | 6 |
| `BOT_MODE_TEAM_ROAM` | 16 |
| `BOT_MODE_WARD` | 22 |
| `COURIER_ACTION_BURST` | 5 |
| `COURIER_ACTION_ENEMY_SECRET_SHOP` | 7 |
| `COURIER_ACTION_RETURN` | 0 |
| `COURIER_ACTION_RETURN_STASH_ITEMS` | 2 |
| `COURIER_ACTION_SECRET_SHOP` | 1 |
| `COURIER_ACTION_SIDE_SHOP` | 8 |
| `COURIER_ACTION_SIDE_SHOP2` | 9 |
| `COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS` | 6 |
| `COURIER_ACTION_TAKE_STASH_ITEMS` | 3 |
| `COURIER_ACTION_TRANSFER_ITEMS` | 4 |
| `COURIER_STATE_AT_BASE` | 1 |
| `COURIER_STATE_AT_SECRET_SHOP` | 7 |
| `COURIER_STATE_DEAD` | 5 |
| `COURIER_STATE_DELIVERING_ITEMS` | 3 |
| `COURIER_STATE_GOING_TO_SECRET_SHOP` | 6 |
| `COURIER_STATE_IDLE` | 0 |
| `COURIER_STATE_MOVING` | 2 |
| `COURIER_STATE_RETURNING_TO_BASE` | 4 |
| `DAMAGE_TYPE_ALL` | 7 |
| `DAMAGE_TYPE_MAGICAL` | 2 |
| `DAMAGE_TYPE_PHYSICAL` | 1 |
| `DAMAGE_TYPE_PURE` | 4 |
| `DIFFICULTY_EASY` | 1 |
| `DIFFICULTY_HARD` | 3 |
| `DIFFICULTY_INVALID` | 5 |
| `DIFFICULTY_MEDIUM` | 2 |
| `DIFFICULTY_NPX` | 9 |
| `DIFFICULTY_PASSIVE` | 0 |
| `DIFFICULTY_UNFAIR` | 4 |
| `GAMEMODE_1V1MID` | 21 |
| `GAMEMODE_ABILITY_DRAFT` | 18 |
| `GAMEMODE_ALL_DRAFT` | 22 |
| `GAMEMODE_AP` | 1 |
| `GAMEMODE_AR` | 5 |
| `GAMEMODE_ARDM` | 20 |
| `GAMEMODE_CD` | 16 |
| `GAMEMODE_CM` | 2 |
| `GAMEMODE_MO` | 11 |
| `GAMEMODE_MUTATION` | 24 |
| `GAMEMODE_NONE` | 0 |
| `GAMEMODE_POOL1` | 13 |
| `GAMEMODE_RD` | 3 |
| `GAMEMODE_REVERSE_CM` | 8 |
| `GAMEMODE_SD` | 4 |
| `GAMEMODE_TURBO` | 23 |
| `GAME_STATE_CUSTOM_GAME_SETUP` | 9 |
| `GAME_STATE_DISCONNECT` | 7 |
| `GAME_STATE_GAME_IN_PROGRESS` | 5 |
| `GAME_STATE_HERO_SELECTION` | 2 |
| `GAME_STATE_INIT` | 0 |
| `GAME_STATE_LAST` | 13 |
| `GAME_STATE_PLAYER_DRAFT` | 12 |
| `GAME_STATE_POST_GAME` | 6 |
| `GAME_STATE_PRE_GAME` | 4 |
| `GAME_STATE_STRATEGY_TIME` | 3 |
| `GAME_STATE_TEAM_SHOWCASE` | 8 |
| `GAME_STATE_WAIT_FOR_MAP_TO_LOAD` | 10 |
| `GAME_STATE_WAIT_FOR_PLAYERS_TO_LOAD` | 1 |
| `GLYPH_COOLDOWN` | 300 |
| `HEROPICK_STATE_ALL_DRAFT_SELECT` | 57 |
| `HEROPICK_STATE_AP_SELECT` | 1 |
| `HEROPICK_STATE_AR_SELECT` | 32 |
| `HEROPICK_STATE_BD_SELECT` | 54 |
| `HEROPICK_STATE_CD_BAN1` | 37 |
| `HEROPICK_STATE_CD_BAN2` | 38 |
| `HEROPICK_STATE_CD_BAN3` | 39 |
| `HEROPICK_STATE_CD_BAN4` | 40 |
| `HEROPICK_STATE_CD_BAN5` | 41 |
| `HEROPICK_STATE_CD_BAN6` | 42 |
| `HEROPICK_STATE_CD_CAPTAINPICK` | 36 |
| `HEROPICK_STATE_CD_INTRO` | 35 |
| `HEROPICK_STATE_CD_PICK` | 53 |
| `HEROPICK_STATE_CD_SELECT1` | 43 |
| `HEROPICK_STATE_CD_SELECT10` | 52 |
| `HEROPICK_STATE_CD_SELECT2` | 44 |
| `HEROPICK_STATE_CD_SELECT3` | 45 |
| `HEROPICK_STATE_CD_SELECT4` | 46 |
| `HEROPICK_STATE_CD_SELECT5` | 47 |
| `HEROPICK_STATE_CD_SELECT6` | 48 |
| `HEROPICK_STATE_CD_SELECT7` | 49 |
| `HEROPICK_STATE_CD_SELECT8` | 50 |
| `HEROPICK_STATE_CD_SELECT9` | 51 |
| `HEROPICK_STATE_CM_BAN1` | 7 |
| `HEROPICK_STATE_CM_BAN10` | 16 |
| `HEROPICK_STATE_CM_BAN11` | 17 |
| `HEROPICK_STATE_CM_BAN12` | 18 |
| `HEROPICK_STATE_CM_BAN13` | 19 |
| `HEROPICK_STATE_CM_BAN14` | 20 |
| `HEROPICK_STATE_CM_BAN2` | 8 |
| `HEROPICK_STATE_CM_BAN3` | 9 |
| `HEROPICK_STATE_CM_BAN4` | 10 |
| `HEROPICK_STATE_CM_BAN5` | 11 |
| `HEROPICK_STATE_CM_BAN6` | 12 |
| `HEROPICK_STATE_CM_BAN7` | 13 |
| `HEROPICK_STATE_CM_BAN8` | 14 |
| `HEROPICK_STATE_CM_BAN9` | 15 |
| `HEROPICK_STATE_CM_CAPTAINPICK` | 6 |
| `HEROPICK_STATE_CM_INTRO` | 5 |
| `HEROPICK_STATE_CM_PICK` | 31 |
| `HEROPICK_STATE_CM_SELECT1` | 21 |
| `HEROPICK_STATE_CM_SELECT10` | 30 |
| `HEROPICK_STATE_CM_SELECT2` | 22 |
| `HEROPICK_STATE_CM_SELECT3` | 23 |
| `HEROPICK_STATE_CM_SELECT4` | 24 |
| `HEROPICK_STATE_CM_SELECT5` | 25 |
| `HEROPICK_STATE_CM_SELECT6` | 26 |
| `HEROPICK_STATE_CM_SELECT7` | 27 |
| `HEROPICK_STATE_CM_SELECT8` | 28 |
| `HEROPICK_STATE_CM_SELECT9` | 29 |
| `HEROPICK_STATE_CUSTOM_PICK_RULES` | 60 |
| `HEROPICK_STATE_FH_SELECT` | 34 |
| `HEROPICK_STATE_MO_SELECT` | 33 |
| `HEROPICK_STATE_NONE` | 0 |
| `HEROPICK_STATE_SCENARIO_PICK` | 61 |
| `HEROPICK_STATE_SD_SELECT` | 2 |
| `HEROPICK_STATE_SELECT_PENALTY` | 59 |
| `HERO_PICK_STATE_ABILITY_DRAFT_SELECT` | 55 |
| `HERO_PICK_STATE_ARDM_SELECT` | 56 |
| `ITEM_SLOT_TYPE_BACKPACK` | 1 |
| `ITEM_SLOT_TYPE_INVALID` | -1 |
| `ITEM_SLOT_TYPE_MAIN` | 0 |
| `ITEM_SLOT_TYPE_STASH` | 2 |
| `LANE_BOT` | 3 |
| `LANE_MID` | 2 |
| `LANE_NONE` | 0 |
| `LANE_TOP` | 1 |
| `PURCHASE_ITEM_DISALLOWED_ITEM` | 78 |
| `PURCHASE_ITEM_INSUFFICIENT_GOLD` | 63 |
| `PURCHASE_ITEM_INVALID_ITEM_NAME` | 33 |
| `PURCHASE_ITEM_NOT_AT_HOME_SHOP` | 67 |
| `PURCHASE_ITEM_NOT_AT_SECRET_SHOP` | 62 |
| `PURCHASE_ITEM_NOT_AT_SIDE_SHOP` | 66 |
| `PURCHASE_ITEM_OUT_OF_STOCK` | 82 |
| `PURCHASE_ITEM_SUCCESS` | -1 |
| `RUNE_ARCANE` | 6 |
| `RUNE_BOUNTY` | 5 |
| `RUNE_BOUNTY_1` | 2 |
| `RUNE_BOUNTY_2` | 3 |
| `RUNE_BOUNTY_3` | 4 |
| `RUNE_BOUNTY_4` | 5 |
| `RUNE_DOUBLEDAMAGE` | 0 |
| `RUNE_HASTE` | 1 |
| `RUNE_ILLUSION` | 2 |
| `RUNE_INVALID` | -1 |
| `RUNE_INVISIBILITY` | 3 |
| `RUNE_POWERUP_1` | 0 |
| `RUNE_POWERUP_2` | 1 |
| `RUNE_REGENERATION` | 4 |
| `RUNE_SHIELD` | 9 |
| `RUNE_STATUS_AVAILABLE` | 1 |
| `RUNE_STATUS_MISSING` | 2 |
| `RUNE_STATUS_UNKNOWN` | 0 |
| `RUNE_WATER` | 7 |
| `RUNE_XP` | 8 |
| `SHOP_HOME` | 0 |
| `SHOP_SECRET` | 2 |
| `SHOP_SECRET2` | 5 |
| `SHOP_SIDE` | 1 |
| `SHOP_SIDE2` | 4 |
| `SHRINE_BASE_1` | 0 |
| `SHRINE_BASE_2` | 1 |
| `SHRINE_BASE_3` | 2 |
| `SHRINE_JUNGLE_1` | 3 |
| `SHRINE_JUNGLE_2` | 4 |
| `TEAM_DIRE` | 3 |
| `TEAM_NEUTRAL` | 4 |
| `TEAM_NONE` | 5 |
| `TEAM_RADIANT` | 2 |
| `TOWER_BASE_1` | 9 |
| `TOWER_BASE_2` | 10 |
| `TOWER_BOT_1` | 6 |
| `TOWER_BOT_2` | 7 |
| `TOWER_BOT_3` | 8 |
| `TOWER_MID_1` | 3 |
| `TOWER_MID_2` | 4 |
| `TOWER_MID_3` | 5 |
| `TOWER_TOP_1` | 0 |
| `TOWER_TOP_2` | 1 |
| `TOWER_TOP_3` | 2 |
| `UNIT_LIST_ALL` | 0 |
| `UNIT_LIST_ALLIED_BUILDINGS` | 5 |
| `UNIT_LIST_ALLIED_CREEPS` | 3 |
| `UNIT_LIST_ALLIED_HEROES` | 2 |
| `UNIT_LIST_ALLIED_OTHER` | 6 |
| `UNIT_LIST_ALLIED_WARDS` | 4 |
| `UNIT_LIST_ALLIES` | 1 |
| `UNIT_LIST_ENEMIES` | 7 |
| `UNIT_LIST_ENEMY_BUILDINGS` | 11 |
| `UNIT_LIST_ENEMY_CREEPS` | 9 |
| `UNIT_LIST_ENEMY_HEROES` | 8 |
| `UNIT_LIST_ENEMY_OTHER` | 12 |
| `UNIT_LIST_ENEMY_WARDS` | 10 |
| `UNIT_LIST_NEUTRAL_CREEPS` | 13 |
| `UNIT_LIST_THINKERS` | 14 |

## Unidades vistas (253; tiempo de juego en segundos)

Valores leídos con los métodos de la unidad; `MaxHealth` y `MagicResist` pasan por reemplazos de OHA (arriba).

- t=-5  team=2 MaxHealth=150.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=700.000 NightTimeVisionRange=700.000
- t=-5 npc_dota_xp_fountain team=4 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_goodguys_tower3_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower3_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower3_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower2_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower1_bot team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=-5 npc_dota_goodguys_tower2_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower2_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_tower1_top team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=-5 npc_dota_goodguys_tower4 team=2 MaxHealth=2600.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=21.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=-5 npc_dota_goodguys_melee_rax_mid team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_goodguys_range_rax_mid team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_goodguys_melee_rax_bot team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_goodguys_range_rax_bot team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_goodguys_melee_rax_top team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_goodguys_range_rax_top team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_badguys_melee_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_range_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_range_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_melee_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_melee_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_range_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_fort team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_goodguys_fort team=2 MaxHealth=4500.000 HealthRegen=12.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=23.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=298.726 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=2600.000 NightTimeVisionRange=2600.000
- t=-5 npc_dota_badguys_tower4 team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower2_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower1_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower2_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower1_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower2_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower3_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower3_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower3_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_goodguys_tower1_mid team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=-5 npc_dota_goodguys_fillers team=2 MaxHealth=1000.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=10.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=-5 npc_dota_badguys_fillers team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 npc_dota_badguys_tower1_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 #DOTA_OutpostName_South team=2 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=-5 #DOTA_OutpostName_North team=3 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=-5 npc_dota_unit_twin_gate team=4 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=500.000 NightTimeVisionRange=500.000
- t=-5 npc_dota_lotus_pool team=4 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 ent_dota_halloffame team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=-5 dota_fountain team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=0  team=2 MaxHealth=150.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=700.000 NightTimeVisionRange=700.000
- t=0 npc_dota_xp_fountain team=4 MaxHealth=1750.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=17.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=0 npc_dota_goodguys_tower3_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower3_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower3_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower2_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower1_bot team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 npc_dota_goodguys_tower2_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower2_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower1_top team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 npc_dota_goodguys_tower4 team=2 MaxHealth=2600.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=21.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_melee_rax_mid team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_goodguys_range_rax_mid team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_goodguys_melee_rax_bot team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_goodguys_range_rax_bot team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_goodguys_melee_rax_top team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_goodguys_range_rax_top team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_melee_rax_bot team=3 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_range_rax_bot team=3 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_range_rax_mid team=3 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_melee_rax_mid team=3 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_melee_rax_top team=3 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_range_rax_top team=3 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_fort team=3 MaxHealth=4500.000 HealthRegen=12.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=23.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=373.962 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=2600.000 NightTimeVisionRange=2600.000
- t=0 npc_dota_goodguys_fort team=2 MaxHealth=4500.000 HealthRegen=12.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=23.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=298.726 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=2600.000 NightTimeVisionRange=2600.000
- t=0 npc_dota_badguys_tower4 team=3 MaxHealth=2600.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=21.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower2_top team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower1_top team=3 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 npc_dota_badguys_tower2_mid team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower1_mid team=3 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 npc_dota_badguys_tower2_bot team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower3_bot team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower3_top team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_badguys_tower3_mid team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=0 npc_dota_goodguys_tower1_mid team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 npc_dota_goodguys_fillers team=2 MaxHealth=1000.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=10.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_fillers team=3 MaxHealth=1000.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=10.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=0 npc_dota_badguys_tower1_bot team=3 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=0 #DOTA_OutpostName_South team=2 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=0 #DOTA_OutpostName_North team=3 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=0 npc_dota_unit_twin_gate team=4 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=500.000 NightTimeVisionRange=500.000
- t=0 npc_dota_lotus_pool team=4 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=500.000 NightTimeVisionRange=500.000
- t=0 ent_dota_halloffame team=3 MaxHealth=150.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=575.000 NightTimeVisionRange=575.000
- t=0 dota_fountain team=3 MaxHealth=500.000 HealthRegen=0.000 BaseDamage=300.000 BaseDamageVariance=10.000 AttackDamage=300.000 AttackRange=1200.000 AttackSpeed=1.000 SecondsPerAttack=0.150 AttackPoint=0.000 AttackProjectileSpeed=1400.000 AcquisitionRange=1200.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1800.000 NightTimeVisionRange=1800.000
- t=5 npc_dota_courier team=2 MaxHealth=6.000 HealthRegen=0.300 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=1100.000 BoundingRadius=8.000 BountyGoldMin=50.000 BountyGoldMax=50.000 BountyXP=0.000 DayTimeVisionRange=200.000 NightTimeVisionRange=200.000
- t=5 npc_dota_creep_goodguys_ranged team=2 MaxHealth=300.000 HealthRegen=2.000 BaseDamage=23.500 BaseDamageVariance=2.500 AttackDamage=23.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=43.000 BountyGoldMax=52.000 BountyXP=69.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=5 npc_dota_observer_wards team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=8.000 BountyGoldMin=100.000 BountyGoldMax=100.000 BountyXP=70.000 DayTimeVisionRange=1600.000 NightTimeVisionRange=1600.000
- t=5 npc_dota_creep_goodguys_melee team=2 MaxHealth=550.000 HealthRegen=0.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=20 npc_dota_creep_badguys_ranged team=3 MaxHealth=300.000 HealthRegen=2.000 BaseDamage=23.500 BaseDamageVariance=2.500 AttackDamage=23.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=43.000 BountyGoldMax=52.000 BountyXP=69.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=20 npc_dota_creep_badguys_melee team=3 MaxHealth=550.000 HealthRegen=0.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=55 npc_dota_warlock_minor_imp team=2 MaxHealth=35.000 HealthRegen=0.500 BaseDamage=10.500 BaseDamageVariance=0.500 AttackDamage=10.000 AttackRange=80.000 AttackSpeed=2.000 SecondsPerAttack=1.000 AttackPoint=0.380 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=1.000 MagicResist=0.000 BaseMovementSpeed=303.000 CurrentMovementSpeed=303.000 BoundingRadius=8.000 BountyGoldMin=3.000 BountyGoldMax=3.000 BountyXP=17.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_wildkin team=4 MaxHealth=350.000 HealthRegen=0.500 BaseDamage=19.000 BaseDamageVariance=1.000 AttackDamage=19.000 AttackRange=128.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=5.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=16.000 BountyGoldMax=18.000 BountyXP=26.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_giant_wolf team=4 MaxHealth=500.000 HealthRegen=0.500 BaseDamage=16.000 BaseDamageVariance=1.000 AttackDamage=19.000 AttackRange=90.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=1.000 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=350.000 BoundingRadius=24.000 BountyGoldMin=18.000 BountyGoldMax=22.000 BountyXP=40.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_froglet_mage team=4 MaxHealth=700.000 HealthRegen=0.500 BaseDamage=25.500 BaseDamageVariance=1.500 AttackDamage=25.000 AttackRange=250.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=319.000 BoundingRadius=24.000 BountyGoldMin=25.000 BountyGoldMax=29.000 BountyXP=42.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_froglet team=4 MaxHealth=700.000 HealthRegen=0.500 BaseDamage=23.000 BaseDamageVariance=1.000 AttackDamage=23.000 AttackRange=100.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=319.000 BoundingRadius=24.000 BountyGoldMin=25.000 BountyGoldMax=29.000 BountyXP=42.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_harpy_scout team=4 MaxHealth=400.000 HealthRegen=0.500 BaseDamage=31.000 BaseDamageVariance=3.000 AttackDamage=31.000 AttackRange=300.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=300.000 Armor=1.000 MagicResist=0.000 BaseMovementSpeed=280.000 CurrentMovementSpeed=280.000 BoundingRadius=24.000 BountyGoldMin=14.000 BountyGoldMax=16.000 BountyXP=26.000 DayTimeVisionRange=1200.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_enraged_wildkin team=4 MaxHealth=950.000 HealthRegen=0.500 BaseDamage=53.000 BaseDamageVariance=3.000 AttackDamage=53.000 AttackRange=128.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=7.000 MagicResist=0.000 BaseMovementSpeed=320.000 CurrentMovementSpeed=320.000 BoundingRadius=24.000 BountyGoldMin=58.000 BountyGoldMax=64.000 BountyXP=90.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_alpha_wolf team=4 MaxHealth=600.000 HealthRegen=0.500 BaseDamage=28.000 BaseDamageVariance=1.000 AttackDamage=33.000 AttackRange=90.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=3.000 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=350.000 BoundingRadius=24.000 BountyGoldMin=32.000 BountyGoldMax=34.000 BountyXP=60.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=60 npc_dota_neutral_harpy_storm team=4 MaxHealth=500.000 HealthRegen=0.500 BaseDamage=33.000 BaseDamageVariance=3.000 AttackDamage=33.000 AttackRange=450.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=300.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=310.000 CurrentMovementSpeed=310.000 BoundingRadius=24.000 BountyGoldMin=25.000 BountyGoldMax=27.000 BountyXP=42.000 DayTimeVisionRange=1800.000 NightTimeVisionRange=1800.000
- t=121 npc_dota_creep_goodguys_flagbearer team=2 MaxHealth=550.000 HealthRegen=3.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.400 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=136 npc_dota_creep_badguys_flagbearer team=3 MaxHealth=550.000 HealthRegen=3.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.400 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=161 npc_dota_neutral_warpine_raider team=4 MaxHealth=850.000 HealthRegen=2.500 BaseDamage=40.000 BaseDamageVariance=1.000 AttackDamage=35.000 AttackRange=100.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.300 BaseMovementSpeed=310.000 CurrentMovementSpeed=347.000 BoundingRadius=24.000 BountyGoldMin=48.000 BountyGoldMax=50.000 BountyXP=76.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=161 npc_dota_neutral_forest_troll_berserker team=4 MaxHealth=500.000 HealthRegen=0.500 BaseDamage=32.500 BaseDamageVariance=4.500 AttackDamage=28.000 AttackRange=500.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=300.000 Armor=-3.000 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=302.000 BoundingRadius=24.000 BountyGoldMin=18.000 BountyGoldMax=20.000 BountyXP=28.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=161 npc_dota_neutral_kobold_taskmaster team=4 MaxHealth=400.000 HealthRegen=0.500 BaseDamage=25.000 BaseDamageVariance=1.000 AttackDamage=22.000 AttackRange=110.000 AttackSpeed=2.000 SecondsPerAttack=1.000 AttackPoint=0.380 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=-2.000 MagicResist=0.000 BaseMovementSpeed=330.000 CurrentMovementSpeed=369.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=30.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=302 npc_dota_goodguys_siege team=2 MaxHealth=935.000 HealthRegen=3.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.800 BaseMovementSpeed=325.000 CurrentMovementSpeed=422.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=317 npc_dota_badguys_siege team=3 MaxHealth=935.000 HealthRegen=3.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.800 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=342 npc_dota_warlock_golem team=2 MaxHealth=1500.000 HealthRegen=25.000 BaseDamage=100.000 BaseDamageVariance=10.000 AttackDamage=100.000 AttackRange=225.000 AttackSpeed=1.000 SecondsPerAttack=1.200 AttackPoint=0.260 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=8.000 MagicResist=0.330 BaseMovementSpeed=320.000 CurrentMovementSpeed=320.000 BoundingRadius=24.000 BountyGoldMin=100.000 BountyGoldMax=100.000 BountyXP=98.000 DayTimeVisionRange=1800.000 NightTimeVisionRange=1800.000
- t=393 npc_dota_slark_visual team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=8.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=423 npc_dota_neutral_mud_golem team=4 MaxHealth=750.000 HealthRegen=0.500 BaseDamage=25.000 BaseDamageVariance=1.000 AttackDamage=25.000 AttackRange=100.000 AttackSpeed=1.500 SecondsPerAttack=1.333 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=0.000 MagicResist=0.300 BaseMovementSpeed=310.000 CurrentMovementSpeed=310.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=32.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=433 npc_dota_neutral_forest_troll_high_priest team=4 MaxHealth=450.000 HealthRegen=0.500 BaseDamage=31.000 BaseDamageVariance=3.000 AttackDamage=31.000 AttackRange=600.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.300 AttackProjectileSpeed=900.000 AcquisitionRange=300.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=290.000 BoundingRadius=24.000 BountyGoldMin=18.000 BountyGoldMax=20.000 BountyXP=28.000 DayTimeVisionRange=1400.000 NightTimeVisionRange=800.000
- t=453 npc_dota_courier team=2 MaxHealth=6.000 HealthRegen=0.300 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=1100.000 BoundingRadius=8.000 BountyGoldMin=65.000 BountyGoldMax=65.000 BountyXP=0.000 DayTimeVisionRange=200.000 NightTimeVisionRange=200.000
- t=453 npc_dota_creep_badguys_ranged team=3 MaxHealth=300.000 HealthRegen=2.000 BaseDamage=23.500 BaseDamageVariance=2.500 AttackDamage=23.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=43.000 BountyGoldMax=52.000 BountyXP=69.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=453  team=2 MaxHealth=150.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=700.000 NightTimeVisionRange=700.000
- t=453 npc_dota_xp_fountain team=4 MaxHealth=1750.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=17.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=453 npc_dota_goodguys_tower3_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower3_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower3_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower2_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower1_bot team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=453 npc_dota_goodguys_tower2_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower2_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_tower1_top team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=453 npc_dota_goodguys_tower4 team=2 MaxHealth=2600.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=45.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_goodguys_melee_rax_mid team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_goodguys_range_rax_mid team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_goodguys_melee_rax_bot team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_goodguys_range_rax_bot team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_goodguys_melee_rax_top team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_goodguys_range_rax_top team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_badguys_melee_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_range_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_range_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_melee_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_melee_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_range_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_fort team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_goodguys_fort team=2 MaxHealth=4500.000 HealthRegen=12.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=23.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=298.726 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=2600.000 NightTimeVisionRange=2600.000
- t=453 npc_dota_badguys_tower4 team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower2_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower2_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower1_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower2_bot team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=453 npc_dota_badguys_tower3_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower3_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_badguys_tower3_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_goodguys_tower1_mid team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=453 npc_dota_goodguys_fillers team=2 MaxHealth=1000.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=10.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=453 npc_dota_badguys_fillers team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 #DOTA_OutpostName_South team=2 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=453 #DOTA_OutpostName_North team=3 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=453 npc_dota_unit_twin_gate team=4 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=500.000 NightTimeVisionRange=500.000
- t=453 npc_dota_lotus_pool team=4 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 ent_dota_halloffame team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 dota_fountain team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=453 npc_dota_creep_goodguys_ranged team=2 MaxHealth=312.000 HealthRegen=2.000 BaseDamage=25.500 BaseDamageVariance=2.500 AttackDamage=25.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=46.000 BountyGoldMax=55.000 BountyXP=77.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=453 npc_dota_creep_goodguys_melee team=2 MaxHealth=562.000 HealthRegen=0.500 BaseDamage=22.000 BaseDamageVariance=2.000 AttackDamage=22.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=35.000 BountyGoldMax=40.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=453 npc_dota_creep_badguys_melee team=3 MaxHealth=550.000 HealthRegen=0.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=453 npc_dota_goodguys_siege team=2 MaxHealth=935.000 HealthRegen=0.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.800 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=453 npc_dota_observer_wards team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=8.000 BountyGoldMin=100.000 BountyGoldMax=100.000 BountyXP=130.000 DayTimeVisionRange=1600.000 NightTimeVisionRange=1600.000
- t=453 npc_dota_creep_goodguys_flagbearer team=2 MaxHealth=550.000 HealthRegen=3.500 BaseDamage=21.000 BaseDamageVariance=2.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.424 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=34.000 BountyGoldMax=39.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=488 npc_dota_sentry_wards team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=8.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=493 npc_dota_creep_badguys_flagbearer team=3 MaxHealth=562.000 HealthRegen=3.500 BaseDamage=22.000 BaseDamageVariance=2.000 AttackDamage=22.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.424 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=35.000 BountyGoldMax=40.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=528 npc_dota_warlock_minor_imp team=2 MaxHealth=185.000 HealthRegen=3.500 BaseDamage=10.500 BaseDamageVariance=0.500 AttackDamage=10.000 AttackRange=80.000 AttackSpeed=2.000 SecondsPerAttack=1.000 AttackPoint=0.380 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=1.000 MagicResist=0.040 BaseMovementSpeed=333.000 CurrentMovementSpeed=333.000 BoundingRadius=8.000 BountyGoldMin=3.000 BountyGoldMax=3.000 BountyXP=17.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=549 npc_dota_neutral_mud_golem team=4 MaxHealth=780.000 HealthRegen=0.500 BaseDamage=25.000 BaseDamageVariance=1.000 AttackDamage=28.000 AttackRange=100.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=0.500 MagicResist=0.300 BaseMovementSpeed=310.000 CurrentMovementSpeed=310.000 BoundingRadius=24.000 BountyGoldMin=20.000 BountyGoldMax=22.000 BountyXP=37.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=589 npc_dota_neutral_forest_troll_berserker team=4 MaxHealth=530.000 HealthRegen=0.500 BaseDamage=32.500 BaseDamageVariance=4.500 AttackDamage=27.000 AttackRange=500.000 AttackSpeed=1.300 SecondsPerAttack=1.538 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=300.000 Armor=-4.500 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=33.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=609 npc_dota_badguys_siege team=3 MaxHealth=935.000 HealthRegen=3.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.808 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=654 npc_dota_neutral_froglet team=4 MaxHealth=730.000 HealthRegen=0.500 BaseDamage=23.000 BaseDamageVariance=1.000 AttackDamage=21.000 AttackRange=100.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=-3.500 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=100.000 BoundingRadius=24.000 BountyGoldMin=26.000 BountyGoldMax=30.000 BountyXP=47.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=654 npc_dota_neutral_grown_frog_mage team=4 MaxHealth=930.000 HealthRegen=0.500 BaseDamage=42.500 BaseDamageVariance=2.500 AttackDamage=35.000 AttackRange=250.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=-2.500 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=100.000 BoundingRadius=24.000 BountyGoldMin=38.000 BountyGoldMax=42.000 BountyXP=60.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=654 npc_dota_neutral_grown_frog team=4 MaxHealth=930.000 HealthRegen=0.500 BaseDamage=43.500 BaseDamageVariance=2.500 AttackDamage=36.000 AttackRange=100.000 AttackSpeed=1.400 SecondsPerAttack=1.429 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=-2.500 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=330.000 BoundingRadius=24.000 BountyGoldMin=38.000 BountyGoldMax=42.000 BountyXP=60.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=690 npc_dota_neutral_dark_troll team=4 MaxHealth=530.000 HealthRegen=0.500 BaseDamage=25.500 BaseDamageVariance=1.500 AttackDamage=28.000 AttackRange=250.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=0.500 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=18.000 BountyGoldMax=20.000 BountyXP=47.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=690 npc_dota_neutral_dark_troll_warlord team=4 MaxHealth=1130.000 HealthRegen=0.500 BaseDamage=42.500 BaseDamageVariance=2.500 AttackDamage=45.000 AttackRange=250.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=4.500 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=41.000 BountyGoldMax=47.000 BountyXP=95.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=695 npc_dota_neutral_giant_wolf team=4 MaxHealth=530.000 HealthRegen=0.500 BaseDamage=16.000 BaseDamageVariance=1.000 AttackDamage=22.000 AttackRange=90.000 AttackSpeed=1.300 SecondsPerAttack=1.538 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=1.500 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=350.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=23.000 BountyXP=45.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=710 npc_dota_neutral_alpha_wolf team=4 MaxHealth=630.000 HealthRegen=0.500 BaseDamage=28.000 BaseDamageVariance=1.000 AttackDamage=36.000 AttackRange=90.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=3.500 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=220.000 BoundingRadius=24.000 BountyGoldMin=33.000 BountyGoldMax=35.000 BountyXP=65.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=745 npc_dota_neutral_black_drake team=4 MaxHealth=980.000 HealthRegen=0.500 BaseDamage=21.000 BaseDamageVariance=1.000 AttackDamage=24.000 AttackRange=300.000 AttackSpeed=1.250 SecondsPerAttack=1.600 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=300.000 Armor=5.500 MagicResist=0.250 BaseMovementSpeed=350.000 CurrentMovementSpeed=325.000 BoundingRadius=24.000 BountyGoldMin=38.000 BountyGoldMax=44.000 BountyXP=100.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=745 npc_dota_neutral_black_dragon team=4 MaxHealth=2030.000 HealthRegen=2.000 BaseDamage=65.000 BaseDamageVariance=3.000 AttackDamage=68.000 AttackRange=300.000 AttackSpeed=1.400 SecondsPerAttack=1.429 AttackPoint=0.500 AttackProjectileSpeed=1500.000 AcquisitionRange=300.000 Armor=7.500 MagicResist=0.300 BaseMovementSpeed=300.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=77.000 BountyGoldMax=81.000 BountyXP=129.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=755 npc_dota_neutral_ogre_mauler team=4 MaxHealth=830.000 HealthRegen=0.500 BaseDamage=23.000 BaseDamageVariance=1.000 AttackDamage=26.000 AttackRange=100.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=1.500 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=23.000 BountyGoldMax=27.000 BountyXP=37.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=755 npc_dota_neutral_ogre_magi team=4 MaxHealth=630.000 HealthRegen=0.500 BaseDamage=19.000 BaseDamageVariance=1.000 AttackDamage=22.000 AttackRange=100.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=0.500 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=29.000 BountyGoldMax=33.000 BountyXP=53.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=760 npc_dota_neutral_froglet_mage team=4 MaxHealth=730.000 HealthRegen=0.500 BaseDamage=25.500 BaseDamageVariance=1.500 AttackDamage=28.000 AttackRange=250.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=2.500 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=319.000 BoundingRadius=24.000 BountyGoldMin=26.000 BountyGoldMax=30.000 BountyXP=47.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=770 npc_dota_neutral_gnoll_assassin team=4 MaxHealth=430.000 HealthRegen=0.500 BaseDamage=26.000 BaseDamageVariance=1.000 AttackDamage=29.000 AttackRange=500.000 AttackSpeed=1.300 SecondsPerAttack=1.538 AttackPoint=0.400 AttackProjectileSpeed=1500.000 AcquisitionRange=800.000 Armor=1.500 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=17.000 BountyGoldMax=19.000 BountyXP=35.000 DayTimeVisionRange=400.000 NightTimeVisionRange=400.000
- t=876 npc_dota_neutral_prowler_shaman team=4 MaxHealth=1430.000 HealthRegen=9.500 BaseDamage=62.000 BaseDamageVariance=3.000 AttackDamage=65.000 AttackRange=100.000 AttackSpeed=1.400 SecondsPerAttack=1.429 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=12.500 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=77.000 BountyGoldMax=81.000 BountyXP=129.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=886 npc_dota_neutral_rock_golem team=4 MaxHealth=962.000 HealthRegen=0.500 BaseDamage=23.000 BaseDamageVariance=1.000 AttackDamage=26.000 AttackRange=100.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=4.500 MagicResist=0.300 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=38.000 BountyGoldMax=44.000 BountyXP=100.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=886 npc_dota_neutral_granite_golem team=4 MaxHealth=1774.000 HealthRegen=1.500 BaseDamage=82.000 BaseDamageVariance=2.000 AttackDamage=85.000 AttackRange=128.000 AttackSpeed=1.550 SecondsPerAttack=1.290 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=8.500 MagicResist=0.300 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=77.000 BountyGoldMax=81.000 BountyXP=129.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=901 npc_dota_creep_badguys_ranged team=3 MaxHealth=312.000 HealthRegen=2.000 BaseDamage=25.500 BaseDamageVariance=2.500 AttackDamage=25.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=46.000 BountyGoldMax=55.000 BountyXP=77.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901 npc_dota_courier team=2 MaxHealth=6.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=290.000 CurrentMovementSpeed=1100.000 BoundingRadius=8.000 BountyGoldMin=95.000 BountyGoldMax=95.000 BountyXP=0.000 DayTimeVisionRange=200.000 NightTimeVisionRange=200.000
- t=901 npc_dota_creep_goodguys_melee team=2 MaxHealth=562.000 HealthRegen=0.500 BaseDamage=22.000 BaseDamageVariance=2.000 AttackDamage=22.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=35.000 BountyGoldMax=40.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901  team=2 MaxHealth=150.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=700.000 NightTimeVisionRange=700.000
- t=901 npc_dota_creep_goodguys_ranged team=2 MaxHealth=312.000 HealthRegen=4.000 BaseDamage=25.500 BaseDamageVariance=2.500 AttackDamage=25.000 AttackRange=500.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.500 AttackProjectileSpeed=900.000 AcquisitionRange=600.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=8.000 BountyGoldMin=46.000 BountyGoldMax=55.000 BountyXP=77.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901 npc_dota_xp_fountain team=4 MaxHealth=1750.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=17.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=901 npc_dota_goodguys_tower3_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower3_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower3_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower2_bot team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower1_bot team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=901 npc_dota_goodguys_tower2_mid team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower2_top team=2 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_tower1_top team=2 MaxHealth=1800.000 HealthRegen=0.000 BaseDamage=90.000 BaseDamageVariance=2.000 AttackDamage=90.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=800.000
- t=901 npc_dota_goodguys_tower4 team=2 MaxHealth=2600.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=45.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_goodguys_melee_rax_mid team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_goodguys_range_rax_mid team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_goodguys_melee_rax_bot team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_goodguys_range_rax_bot team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_goodguys_melee_rax_top team=2 MaxHealth=2200.000 HealthRegen=5.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=15.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_goodguys_range_rax_top team=2 MaxHealth=1300.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=9.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_badguys_melee_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_range_rax_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_range_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_melee_rax_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_melee_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_range_rax_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_fort team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_goodguys_fort team=2 MaxHealth=4500.000 HealthRegen=12.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=23.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=298.726 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=2600.000 NightTimeVisionRange=2600.000
- t=901 npc_dota_badguys_tower4 team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_tower2_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_tower2_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_tower2_bot team=3 MaxHealth=2500.000 HealthRegen=0.000 BaseDamage=172.000 BaseDamageVariance=2.000 AttackDamage=172.000 AttackRange=700.000 AttackSpeed=1.100 SecondsPerAttack=0.818 AttackPoint=0.600 AttackProjectileSpeed=750.000 AcquisitionRange=700.000 Armor=16.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=144.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=1900.000 NightTimeVisionRange=1100.000
- t=901 npc_dota_badguys_tower3_bot team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_tower3_top team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_badguys_tower3_mid team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_goodguys_fillers team=2 MaxHealth=1000.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=10.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=900.000 NightTimeVisionRange=600.000
- t=901 npc_dota_badguys_fillers team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=68.000 BountyGoldMax=68.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 #DOTA_OutpostName_South team=2 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=901 #DOTA_OutpostName_North team=3 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=901 npc_dota_unit_twin_gate team=4 MaxHealth=450.000 HealthRegen=0.000 BaseDamage=0.000 BaseDamageVariance=0.000 AttackDamage=0.000 AttackRange=0.000 AttackSpeed=1.000 SecondsPerAttack=0.000 AttackPoint=0.000 AttackProjectileSpeed=0.000 AcquisitionRange=0.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=0.000 CurrentMovementSpeed=100.000 BoundingRadius=96.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=500.000 NightTimeVisionRange=500.000
- t=901 npc_dota_lotus_pool team=4 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 ent_dota_halloffame team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 dota_fountain team=3 MaxHealth=-1.000 HealthRegen=-1.000 BaseDamage=-1.000 BaseDamageVariance=-1.000 AttackDamage=-1.000 AttackRange=200.000 AttackSpeed=-1.000 SecondsPerAttack=-1.000 AttackPoint=-1.000 AttackProjectileSpeed=-1.000 AcquisitionRange=-1.000 Armor=-1.000 MagicResist=1.000 BaseMovementSpeed=-1.000 CurrentMovementSpeed=-1.000 BoundingRadius=-1.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=-1.000 NightTimeVisionRange=-1.000
- t=901 npc_dota_sentry_wards team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=8.000 BountyGoldMin=0.000 BountyGoldMax=0.000 BountyXP=0.000 DayTimeVisionRange=0.000 NightTimeVisionRange=0.000
- t=901 npc_dota_neutral_prowler_acolyte team=4 MaxHealth=810.000 HealthRegen=9.500 BaseDamage=35.500 BaseDamageVariance=2.500 AttackDamage=41.000 AttackRange=100.000 AttackSpeed=1.450 SecondsPerAttack=1.379 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=12.000 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=40.000 BountyGoldMax=46.000 BountyXP=105.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=901 npc_dota_goodguys_siege team=2 MaxHealth=935.000 HealthRegen=3.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.816 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901 npc_dota_creep_badguys_melee team=3 MaxHealth=562.000 HealthRegen=0.500 BaseDamage=22.000 BaseDamageVariance=2.000 AttackDamage=22.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=35.000 BountyGoldMax=40.000 BountyXP=57.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901 npc_dota_neutral_prowler_shaman team=4 MaxHealth=1460.000 HealthRegen=9.500 BaseDamage=62.000 BaseDamageVariance=3.000 AttackDamage=68.000 AttackRange=100.000 AttackSpeed=1.450 SecondsPerAttack=1.379 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=13.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=79.000 BountyGoldMax=83.000 BountyXP=134.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=901 npc_dota_creep_goodguys_flagbearer team=2 MaxHealth=574.000 HealthRegen=3.500 BaseDamage=23.000 BaseDamageVariance=2.000 AttackDamage=23.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.448 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=36.000 BountyGoldMax=41.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=901 npc_dota_observer_wards team=2 MaxHealth=100.000 HealthRegen=0.000 BaseDamage=1.000 BaseDamageVariance=0.000 AttackDamage=1.000 AttackRange=600.000 AttackSpeed=1.000 SecondsPerAttack=1.700 AttackPoint=0.750 AttackProjectileSpeed=900.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=8.000 BountyGoldMin=100.000 BountyGoldMax=100.000 BountyXP=190.000 DayTimeVisionRange=1600.000 NightTimeVisionRange=1600.000
- t=911 npc_dota_neutral_centaur_khan team=4 MaxHealth=1160.000 HealthRegen=1.000 BaseDamage=52.000 BaseDamageVariance=3.000 AttackDamage=58.000 AttackRange=100.000 AttackSpeed=1.450 SecondsPerAttack=1.379 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=5.000 MagicResist=0.240 BaseMovementSpeed=320.000 CurrentMovementSpeed=320.000 BoundingRadius=24.000 BountyGoldMin=57.000 BountyGoldMax=63.000 BountyXP=100.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=911 npc_dota_neutral_rock_golem team=4 MaxHealth=997.000 HealthRegen=0.500 BaseDamage=23.000 BaseDamageVariance=1.000 AttackDamage=29.000 AttackRange=100.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=5.000 MagicResist=0.300 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=40.000 BountyGoldMax=46.000 BountyXP=105.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=911 npc_dota_neutral_centaur_outrunner team=4 MaxHealth=410.000 HealthRegen=0.500 BaseDamage=19.000 BaseDamageVariance=1.000 AttackDamage=25.000 AttackRange=100.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.240 BaseMovementSpeed=320.000 CurrentMovementSpeed=320.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=42.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=911 npc_dota_neutral_granite_golem team=4 MaxHealth=1809.000 HealthRegen=1.500 BaseDamage=82.000 BaseDamageVariance=2.000 AttackDamage=88.000 AttackRange=128.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=9.000 MagicResist=0.300 BaseMovementSpeed=270.000 CurrentMovementSpeed=270.000 BoundingRadius=24.000 BountyGoldMin=79.000 BountyGoldMax=83.000 BountyXP=134.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=916 npc_dota_neutral_warpine_raider team=4 MaxHealth=910.000 HealthRegen=2.500 BaseDamage=40.000 BaseDamageVariance=1.000 AttackDamage=46.000 AttackRange=100.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=7.000 MagicResist=0.300 BaseMovementSpeed=310.000 CurrentMovementSpeed=201.000 BoundingRadius=24.000 BountyGoldMin=51.000 BountyGoldMax=53.000 BountyXP=86.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=921 npc_dota_creep_badguys_flagbearer team=3 MaxHealth=574.000 HealthRegen=3.500 BaseDamage=23.000 BaseDamageVariance=2.000 AttackDamage=23.000 AttackRange=100.000 AttackSpeed=1.000 SecondsPerAttack=1.000 AttackPoint=0.467 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.448 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=36.000 BountyGoldMax=41.000 BountyXP=60.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=921 npc_dota_badguys_siege team=3 MaxHealth=935.000 HealthRegen=3.000 BaseDamage=40.500 BaseDamageVariance=5.500 AttackDamage=40.000 AttackRange=690.000 AttackSpeed=1.000 SecondsPerAttack=3.000 AttackPoint=0.700 AttackProjectileSpeed=1100.000 AcquisitionRange=800.000 Armor=0.000 MagicResist=0.816 BaseMovementSpeed=325.000 CurrentMovementSpeed=325.000 BoundingRadius=16.000 BountyGoldMin=59.000 BountyGoldMax=72.000 BountyXP=88.000 DayTimeVisionRange=750.000 NightTimeVisionRange=750.000
- t=926 npc_dota_neutral_grown_frog team=4 MaxHealth=960.000 HealthRegen=0.500 BaseDamage=43.500 BaseDamageVariance=2.500 AttackDamage=49.000 AttackRange=100.000 AttackSpeed=1.450 SecondsPerAttack=1.379 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=4.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=336.000 BoundingRadius=24.000 BountyGoldMin=39.000 BountyGoldMax=43.000 BountyXP=65.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=926 npc_dota_neutral_grown_frog_mage team=4 MaxHealth=960.000 HealthRegen=0.500 BaseDamage=42.500 BaseDamageVariance=2.500 AttackDamage=48.000 AttackRange=250.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=1200.000 AcquisitionRange=250.000 Armor=4.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=336.000 BoundingRadius=24.000 BountyGoldMin=39.000 BountyGoldMax=43.000 BountyXP=65.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=936 npc_dota_neutral_satyr_trickster team=4 MaxHealth=360.000 HealthRegen=0.500 BaseDamage=11.000 BaseDamageVariance=1.000 AttackDamage=17.000 AttackRange=280.000 AttackSpeed=1.350 SecondsPerAttack=1.481 AttackPoint=0.300 AttackProjectileSpeed=1500.000 AcquisitionRange=280.000 Armor=1.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=15.000 BountyGoldMax=17.000 BountyXP=34.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=936 npc_dota_neutral_satyr_soulstealer team=4 MaxHealth=660.000 HealthRegen=0.500 BaseDamage=22.000 BaseDamageVariance=1.000 AttackDamage=28.000 AttackRange=100.000 AttackSpeed=1.350 SecondsPerAttack=1.481 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=300.000 Armor=3.000 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=100.000 BoundingRadius=24.000 BountyGoldMin=21.000 BountyGoldMax=25.000 BountyXP=56.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=936 npc_dota_neutral_gnoll_assassin team=4 MaxHealth=460.000 HealthRegen=0.500 BaseDamage=26.000 BaseDamageVariance=1.000 AttackDamage=32.000 AttackRange=500.000 AttackSpeed=1.350 SecondsPerAttack=1.481 AttackPoint=0.400 AttackProjectileSpeed=1500.000 AcquisitionRange=800.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=270.000 CurrentMovementSpeed=100.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=40.000 DayTimeVisionRange=400.000 NightTimeVisionRange=400.000
- t=956 npc_dota_neutral_wildkin team=4 MaxHealth=410.000 HealthRegen=0.500 BaseDamage=19.000 BaseDamageVariance=1.000 AttackDamage=25.000 AttackRange=128.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=6.000 MagicResist=0.000 BaseMovementSpeed=300.000 CurrentMovementSpeed=300.000 BoundingRadius=24.000 BountyGoldMin=19.000 BountyGoldMax=21.000 BountyXP=36.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=956 npc_dota_neutral_enraged_wildkin team=4 MaxHealth=1010.000 HealthRegen=0.500 BaseDamage=53.000 BaseDamageVariance=3.000 AttackDamage=59.000 AttackRange=128.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.300 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=8.000 MagicResist=0.000 BaseMovementSpeed=320.000 CurrentMovementSpeed=320.000 BoundingRadius=24.000 BountyGoldMin=61.000 BountyGoldMax=67.000 BountyXP=100.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=966 npc_dota_neutral_giant_wolf team=4 MaxHealth=560.000 HealthRegen=0.500 BaseDamage=16.000 BaseDamageVariance=1.000 AttackDamage=25.000 AttackRange=90.000 AttackSpeed=1.350 SecondsPerAttack=1.481 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=2.000 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=350.000 BoundingRadius=24.000 BountyGoldMin=21.000 BountyGoldMax=25.000 BountyXP=50.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
- t=966 npc_dota_neutral_alpha_wolf team=4 MaxHealth=660.000 HealthRegen=0.500 BaseDamage=28.000 BaseDamageVariance=1.000 AttackDamage=39.000 AttackRange=90.000 AttackSpeed=1.600 SecondsPerAttack=1.250 AttackPoint=0.330 AttackProjectileSpeed=0.000 AcquisitionRange=500.000 Armor=4.000 MagicResist=0.000 BaseMovementSpeed=350.000 CurrentMovementSpeed=350.000 BoundingRadius=24.000 BountyGoldMin=35.000 BountyGoldMax=37.000 BountyXP=70.000 DayTimeVisionRange=800.000 NightTimeVisionRange=800.000
