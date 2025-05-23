// Internal imports

use registry::constants;
pub use registry::models::index::Game;
use registry::types::config::Config;
use registry::helpers::json::JsonifiableTrait;

// Errors

pub mod errors {
    pub const GAME_ALREADY_EXISTS: felt252 = 'Game: already exists';
    pub const GAME_NOT_EXIST: felt252 = 'Game: does not exist';
    pub const GAME_INVALID_PROJECT: felt252 = 'Game: invalid project';
    pub const GAME_INVALID_OWNER: felt252 = 'Game: invalid owner';
    pub const GAME_INVALID_WORLD: felt252 = 'Game: invalid world';
    pub const GAME_INVALID_NAMESPACE: felt252 = 'Game: invalid namespace';
    pub const GAME_INVALID_NAME: felt252 = 'Game: invalid name';
    pub const GAME_INVALID_PRIORITY: felt252 = 'Game: invalid priority';
    pub const GAME_INVALID_KARMA: felt252 = 'Game: cannot exceed 1000';
    pub const GAME_NOT_WHITELISTABLE: felt252 = 'Game: not whitelistable';
    pub const GAME_NOT_OWNER: felt252 = 'Game: caller is not owner';
}

#[generate_trait]
pub impl GameImpl of GameTrait {
    #[inline]
    fn new(
        world_address: felt252,
        namespace: felt252,
        config: Config,
        metadata: ByteArray,
        socials: ByteArray,
        owner: felt252,
    ) -> Game {
        // [Check] Inputs
        GameAssert::assert_valid_config(config.clone());
        GameAssert::assert_valid_owner(owner);
        GameAssert::assert_valid_world(world_address);
        GameAssert::assert_valid_namespace(namespace);
        // [Return] Game
        Game {
            world_address: world_address,
            namespace: namespace,
            active: true,
            published: false,
            whitelisted: false,
            points: 0,
            priority: 0,
            config: config.jsonify(),
            socials: socials,
            metadata: metadata,
            owner: owner,
        }
    }

    #[inline]
    fn add(ref self: Game, points: u16) {
        // [Check] Inputs
        let total_points = self.points + points;
        GameAssert::assert_valid_points(total_points);
        // [Update] Points
        self.points = total_points;
        // [Effect] Reset visibility status
        self.published = false;
        self.whitelisted = false;
    }

    #[inline]
    fn remove(ref self: Game, points: u16) {
        self.points -= points;
        // [Effect] Reset visibility status
        self.published = false;
        self.whitelisted = false;
    }

    #[inline]
    fn update(ref self: Game, config: Config, metadata: ByteArray, socials: ByteArray) {
        // [Effect] Update Game
        self.config = config.jsonify();
        self.metadata = metadata;
        self.socials = socials;
        // [Effect] Reset visibility status
        self.published = false;
        self.whitelisted = false;
    }

    #[inline]
    fn publish(ref self: Game) {
        // [Effect] Set visibility status
        self.published = true;
        self.whitelisted = false;
    }

    #[inline]
    fn hide(ref self: Game) {
        // [Effect] Reset visibility status
        self.published = false;
    }

    #[inline]
    fn whitelist(ref self: Game) {
        // [Check] Achievement is whitelistable
        GameAssert::assert_is_whitelistable(@self);
        // [Effect] Whitelist
        self.whitelisted = true;
    }

    #[inline]
    fn blacklist(ref self: Game) {
        // [Effect] Reset visibility status
        self.whitelisted = false;
    }

    #[inline]
    fn nullify(ref self: Game) {
        self.published = false;
        self.whitelisted = false;
        self.config = Default::default();
    }
}

#[generate_trait]
pub impl GameAssert of AssertTrait {
    #[inline]
    fn assert_does_not_exist(self: @Game) {
        assert(self.config == Default::default(), errors::GAME_ALREADY_EXISTS);
    }

    #[inline]
    fn assert_does_exist(self: @Game) {
        assert(self.config != Default::default(), errors::GAME_NOT_EXIST);
    }

    #[inline]
    fn assert_valid_config(config: Config) {
        assert(config != Default::default(), errors::GAME_INVALID_PROJECT);
    }

    #[inline]
    fn assert_valid_owner(owner: felt252) {
        assert(owner != 0, errors::GAME_INVALID_OWNER);
    }

    #[inline]
    fn assert_valid_world(world: felt252) {
        assert(world != 0, errors::GAME_INVALID_WORLD);
    }

    #[inline]
    fn assert_valid_namespace(namespace: felt252) {
        assert(namespace != 0, errors::GAME_INVALID_NAMESPACE);
    }

    #[inline]
    fn assert_valid_points(points: u16) {
        assert(points <= constants::MAX_GAME_KARMA, errors::GAME_INVALID_KARMA);
    }

    #[inline]
    fn assert_is_whitelistable(self: @Game) {
        assert(*self.published, errors::GAME_NOT_WHITELISTABLE);
    }

    #[inline]
    fn assert_is_owner(self: @Game, caller: felt252) {
        assert(@caller == self.owner, errors::GAME_NOT_OWNER);
    }
}

#[cfg(test)]
mod tests {
    // Internal imports

    use registry::types::config::{ConfigTrait, ConfigJsonifiable};
    // Local imports

    use super::{GameTrait, GameAssert};

    // Constants

    const WORLD_ADDRESS: felt252 = 'WORLD';
    const NAMESPACE: felt252 = 'NAMESPACE';
    const OWNER: felt252 = 'OWNER';
    #[test]
    fn test_game_new() {
        let metadata = core::traits::Default::default();
        let socials = core::traits::Default::default();
        let config = ConfigTrait::new("PROJECT", "RPC", "POLICIES");
        let game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: config.clone(),
            metadata: metadata.clone(),
            socials: socials.clone(),
            owner: OWNER,
        );
        assert_eq!(game.world_address, WORLD_ADDRESS);
        assert_eq!(game.namespace, NAMESPACE);
        assert_eq!(game.active, true);
        assert_eq!(game.published, false);
        assert_eq!(game.whitelisted, false);
        assert_eq!(game.points, 0);
        assert_eq!(game.priority, 0);
        assert_eq!(game.config, config.jsonify());
        assert_eq!(game.socials, socials.clone().jsonify());
        assert_eq!(game.metadata, metadata.clone().jsonify());
        assert_eq!(game.owner, OWNER);
    }

    #[test]
    fn test_game_add() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.add(100);
        assert_eq!(game.points, 100);
    }

    #[test]
    fn test_game_remove() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.add(100);
        assert_eq!(game.points, 100);
        game.remove(50);
        assert_eq!(game.points, 50);
    }

    #[test]
    fn test_game_update() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        let project = "TCEJORP";
        let rpc = "CPR";
        let policies = "SEICILOP";
        let config = ConfigTrait::new(project, rpc, policies);
        let metadata = "{\"color\": \"#123456\"}";
        let socials = "{\"discord\": \"discord\"}";
        game.update(config.clone(), metadata.clone(), socials.clone());
        assert_eq!(game.config, config.jsonify());
        assert_eq!(game.metadata, metadata.clone().jsonify());
        assert_eq!(game.socials, socials.clone().jsonify());
    }

    #[test]
    fn test_game_publish() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.publish();
        assert_eq!(game.published, true);
    }

    #[test]
    fn test_game_hide() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.publish();
        game.hide();
        assert_eq!(game.published, false);
    }

    #[test]
    fn test_game_whitelist() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.publish();
        game.whitelist();
        assert_eq!(game.whitelisted, true);
    }

    #[test]
    fn test_game_blacklist() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.publish();
        game.whitelist();
        game.blacklist();
        assert_eq!(game.whitelisted, false);
    }

    #[test]
    fn test_game_nullify() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.nullify();
        assert_eq!(game.config, Default::default());
        assert_eq!(game.whitelisted, false);
        assert_eq!(game.published, false);
    }

    #[test]
    #[should_panic(expected: 'Game: already exists')]
    fn test_game_assert_does_not_exist() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.assert_does_not_exist();
    }

    #[test]
    #[should_panic(expected: 'Game: does not exist')]
    fn test_game_assert_does_exist() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.config = Default::default();
        game.assert_does_exist();
    }

    #[test]
    #[should_panic(expected: 'Game: invalid world')]
    fn test_game_assert_valid_world_zero() {
        GameAssert::assert_valid_world(0);
    }

    #[test]
    #[should_panic(expected: 'Game: invalid namespace')]
    fn test_game_assert_valid_namespace_zero() {
        GameAssert::assert_valid_namespace(0);
    }

    #[test]
    #[should_panic(expected: 'Game: invalid project')]
    fn test_game_assert_valid_project_zero() {
        let config = Default::default();
        GameAssert::assert_valid_config(config);
    }

    #[test]
    #[should_panic(expected: 'Game: invalid owner')]
    fn test_game_assert_valid_owner_zero() {
        GameAssert::assert_valid_owner(0);
    }

    #[test]
    #[should_panic(expected: 'Game: cannot exceed 1000')]
    fn test_game_assert_valid_points_exceeds_max() {
        GameAssert::assert_valid_points(1001);
    }

    #[test]
    #[should_panic(expected: 'Game: not whitelistable')]
    fn test_game_assert_is_whitelistable_not_published() {
        let mut game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.publish();
        game.hide();
        game.whitelist();
    }

    #[test]
    #[should_panic(expected: 'Game: caller is not owner')]
    fn test_game_assert_is_owner() {
        let game = GameTrait::new(
            world_address: WORLD_ADDRESS,
            namespace: NAMESPACE,
            config: ConfigTrait::new("PROJECT", "RPC", "POLICIES"),
            metadata: core::traits::Default::default(),
            socials: core::traits::Default::default(),
            owner: OWNER,
        );
        game.assert_is_owner('CALLER');
    }
}
