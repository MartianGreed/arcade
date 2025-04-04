// Internal imports

use registry::helpers::json::{JsonifiableString, JsonifiableTrait};

// Constants

const COLOR_LENGTH: usize = 7;

#[derive(Clone, Drop)]
pub struct Metadata {
    pub color: felt252,
    pub preset: ByteArray,
    pub name: ByteArray,
    pub description: ByteArray,
    pub image: ByteArray,
    pub banner: ByteArray,
}

// Implementations

#[generate_trait]
pub impl MetadataImpl of MetadataTrait {
    fn new(
        color: Option<felt252>,
        preset: Option<ByteArray>,
        name: Option<ByteArray>,
        description: Option<ByteArray>,
        image: Option<ByteArray>,
        banner: Option<ByteArray>,
    ) -> Metadata {
        let color = match color {
            Option::Some(color) => color,
            Option::None => 0,
        };
        let preset = match preset {
            Option::Some(preset) => preset,
            Option::None => "",
        };
        let name = match name {
            Option::Some(name) => name,
            Option::None => "",
        };
        let description = match description {
            Option::Some(description) => description,
            Option::None => "",
        };
        let image = match image {
            Option::Some(image) => image,
            Option::None => "",
        };
        let banner = match banner {
            Option::Some(banner) => banner,
            Option::None => "",
        };
        Metadata {
            color: color,
            preset: preset,
            name: name,
            description: description,
            image: image,
            banner: banner,
        }
    }
}

pub impl MetadataJsonifiable of JsonifiableTrait<Metadata> {
    fn jsonify(self: Metadata) -> ByteArray {
        let mut color = "";
        if self.color != 0 {
            color.append_word(self.color, COLOR_LENGTH);
        }
        let mut string = "{";
        string += JsonifiableString::jsonify("color", format!("{}", color));
        string += "," + JsonifiableString::jsonify("preset", format!("{}", self.preset));
        string += "," + JsonifiableString::jsonify("name", format!("{}", self.name));
        string += "," + JsonifiableString::jsonify("description", format!("{}", self.description));
        string += "," + JsonifiableString::jsonify("image", format!("{}", self.image));
        string += "," + JsonifiableString::jsonify("banner", format!("{}", self.banner));
        string + "}"
    }
}

pub impl MetadataDefault of core::traits::Default<Metadata> {
    fn default() -> Metadata {
        MetadataTrait::new(
            Option::None, Option::None, Option::None, Option::None, Option::None, Option::None,
        )
    }
}

#[cfg(test)]
mod tests {
    // Local imports

    use super::{Metadata, JsonifiableTrait};

    #[test]
    fn test_metadata_jsonify() {
        let metadata = Metadata {
            color: '#123456',
            preset: "preset",
            name: "name",
            description: "description",
            image: "image",
            banner: "banner",
        };
        let json = metadata.jsonify();
        assert_eq!(
            json,
            "{\"color\":\"#123456\",\"preset\":\"preset\",\"name\":\"name\",\"description\":\"description\",\"image\":\"image\",\"banner\":\"banner\"}",
        );
    }
}
