import { Unit } from "bots/ts_libs/dota";

// dota-bot team brain (bots/FunLib/team_brain.lua, hand-written Lua; benchmark variant "cerebro" only).
/** @noSelf **/
export declare function Enabled(): boolean;
/** @noSelf **/
export declare function PushDesire(bot: Unit, lane: number): number | undefined;
/** @noSelf **/
export declare function DefendDesire(bot: Unit, lane: number): number | undefined;
