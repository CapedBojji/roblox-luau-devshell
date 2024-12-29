{
    description = "Template builder for Roblox Luau development environments";
    inputs = {};
    outputs = inputs@{...}: {
        templates.default = {
            path = ./template;
            description = "Roblox Luau development environment template";
        };
    };
}