import { NAMESPACE } from "../../constants";
import { shortString, addAddressPadding } from "starknet";
import { SchemaType } from "../../bindings";
import { MemberClause, ParsedEntity } from "@dojoengine/sdk";
import { Metadata, Socials } from "../../classes";

const MODEL_NAME = "Game";

export class GameModel {
  type = MODEL_NAME;

  constructor(
    public worldAddress: string,
    public namespace: string,
    public project: string,
    public preset: string,
    public active: boolean,
    public published: boolean,
    public whitelisted: boolean,
    public priority: number,
    public karma: number,
    public metadata: Metadata,
    public socials: Socials,
    public owner: string,
  ) {
    this.worldAddress = worldAddress;
    this.namespace = namespace;
    this.project = project;
    this.preset = preset;
    this.active = active;
    this.published = published;
    this.whitelisted = whitelisted;
    this.priority = priority;
    this.karma = karma;
    this.metadata = metadata;
    this.socials = socials;
    this.owner = owner;
  }

  static from(model: any) {
    const worldAddress = addAddressPadding(model.world_address);
    const namespace = shortString.decodeShortString(`0x${BigInt(model.namespace).toString(16)}`);
    const project = shortString.decodeShortString(`0x${BigInt(model.project).toString(16)}`);
    const preset = shortString.decodeShortString(`0x${BigInt(model.preset).toString(16)}`);
    const active = !!model.active;
    const published = !!model.published;
    const whitelisted = !!model.whitelisted;
    const priority = Number(model.priority);
    const karma = Number(model.karma);
    const metadata = Metadata.from(model.metadata);
    const socials = Socials.from(model.socials);
    const owner = addAddressPadding(model.owner);
    return new GameModel(
      worldAddress,
      namespace,
      project,
      preset,
      active,
      published,
      whitelisted,
      priority,
      karma,
      metadata,
      socials,
      owner,
    );
  }

  static isType(model: GameModel) {
    return model.type === MODEL_NAME;
  }
}

export const Game = {
  parse: (entity: ParsedEntity<SchemaType>) => {
    return GameModel.from(entity.models[NAMESPACE][MODEL_NAME]);
  },

  getModelName: () => {
    return MODEL_NAME;
  },

  getClause: () => {
    return MemberClause(`${NAMESPACE}-${Game.getModelName()}`, "world_address", "Neq", "0x0");
  },

  getMethods: () => [
    { name: "register_game", entrypoint: "register_game", description: "Register a game." },
    { name: "update_game", entrypoint: "update_game", description: "Update a game." },
    { name: "publish_game", entrypoint: "publish_game", description: "Publish a game." },
    { name: "hide_game", entrypoint: "hide_game", description: "Hide a game." },
    { name: "whitelist_game", entrypoint: "whitelist_game", description: "Whitelist a game." },
    { name: "blacklist_game", entrypoint: "blacklist_game", description: "Blacklist a game." },
    { name: "remove_game", entrypoint: "remove_game", description: "Remove a game." },
  ],
};
