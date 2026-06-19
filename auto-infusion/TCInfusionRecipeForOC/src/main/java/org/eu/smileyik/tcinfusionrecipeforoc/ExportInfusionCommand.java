package org.eu.smileyik.tcinfusionrecipeforoc;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import net.minecraft.client.Minecraft;
import net.minecraft.command.CommandBase;
import net.minecraft.command.ICommandSender;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ChatComponentText;

import thaumcraft.api.ThaumcraftApi;
import thaumcraft.api.aspects.AspectList;
import thaumcraft.api.crafting.InfusionRecipe;

public class ExportInfusionCommand extends CommandBase {

    private static final String LUA_TABLE_ENTRY_FORMAT = "[\"%s\"]=%s";
    private static final String LUA_ARRAY_ENTRY_FORMAT = "[%d]=%s";

    @Override
    public int getRequiredPermissionLevel() {
        return 0;
    }

    @Override
    public String getCommandName() {
        return "ExportInfusionRecipes";
    }

    @Override
    public String getCommandUsage(ICommandSender sender) {
        return "Export Infusion Recipes";
    }

    @Override
    public void processCommand(ICommandSender sender, String[] args) {
        File dir = new File(Config.savePath);
        if (!dir.exists()) dir.mkdirs();
        Map<String, Integer> sameNames = new ConcurrentHashMap<>();

        Map<InfusionRecipe, Throwable> filterThrowableMap = new ConcurrentHashMap<>();
        Map<String, String> collect = (Map<String, String>) ThaumcraftApi.getCraftingRecipes()
            .parallelStream()
            .filter(it -> {
                if (it != null && it instanceof InfusionRecipe) {
                    InfusionRecipe recipe = (InfusionRecipe) it;
                    Object recipeOutput = recipe.getRecipeOutput();
                    if (recipe == null || recipeOutput == null) return false;
                    try {
                        ItemStack recipeInput = recipe.getRecipeInput();
                        ItemStack[] components = recipe.getComponents();
                        AspectList aspects = recipe.getAspects();
                        return recipeInput != null && components != null
                            && aspects != null
                            && recipeOutput instanceof ItemStack;
                    } catch (Exception e) {
                        filterThrowableMap.put(recipe, e);
                    }
                }
                return false;
            })
            .collect(Collectors.toMap(it -> {
                InfusionRecipe recipe = (InfusionRecipe) it;
                ItemStack recipeOutput = (ItemStack) recipe.getRecipeOutput();
                String name = recipeOutput.getDisplayName()
                    .replaceAll("[\\\\/:*?\"<>|]", "_");
                Integer i = sameNames.compute(name, (k, v) -> v == null ? 1 : v + 1);
                return i == 1 ? name : (name + " (" + i + ")");
            }, it -> {
                InfusionRecipe recipe = (InfusionRecipe) it;
                ItemStack recipeInput = recipe.getRecipeInput();
                AspectList aspects = recipe.getAspects();
                ItemStack recipeOutput = (ItemStack) recipe.getRecipeOutput();

                Map<String, Integer> aspectsMap = new ConcurrentHashMap<>();
                aspects.aspects.forEach(
                    (key, value) -> {
                        aspectsMap.put(key.getTag(), aspectsMap.getOrDefault(key.getTag(), 0) + value);
                    });

                List<Map<String, Object>> components = Arrays.stream(recipe.getComponents())
                    .filter(Objects::nonNull)
                    .map(ExportInfusionCommand::item2LuaTable)
                    .collect(Collectors.toList());

                Map<String, Object> table = new HashMap<>();
                table.put("aspect", aspectsMap);
                table.put("input", item2LuaTable(recipeInput));
                table.put("components", components);
                table.put("output", item2LuaTable(recipeOutput));
                table.put("instability", recipe.getInstability());
                String luaTable = map2LuaTable(table);
                return luaTable;
            }));
        collect.forEach((key, value) -> {
            try {
                Files.write(new File(dir, key).toPath(), value.getBytes(StandardCharsets.UTF_8));
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
        if (!filterThrowableMap.isEmpty()) {
            Minecraft.getMinecraft().thePlayer
                .addChatMessage(new ChatComponentText("Has exceptions, please view console or log file."));
            filterThrowableMap.forEach((recipe, throwable) -> {
                ItemStack recipeOutput = (ItemStack) recipe.getRecipeOutput();
                MyMod.LOG.error(
                    "Export infusion recipe failed: \n  Recipe: {}\n  Output: {}",
                    recipeOutput,
                    recipeOutput == null ? null : recipeOutput.getDisplayName(),
                    throwable);
            });
        }
        Minecraft.getMinecraft().thePlayer.addChatMessage(new ChatComponentText("Export infusion recipe finished."));
    }

    private static String map2LuaTable(Map<String, ?> map) {
        List<String> list = new ArrayList<>();
        map.forEach((k, v) -> {
            if (v instanceof String) {
                String str = "\"" + ((String) v).replace("\"", "\\\"") + "\"";
                list.add(String.format(LUA_TABLE_ENTRY_FORMAT, k, str));
            } else if (v instanceof Integer || v instanceof Long || v instanceof Byte || v instanceof Short) {
                list.add(String.format(LUA_TABLE_ENTRY_FORMAT, k, v));
            } else if (v instanceof Number) {
                list.add(String.format(LUA_TABLE_ENTRY_FORMAT, k, ((Number) v).doubleValue()));
            } else if (v instanceof Map) {
                list.add(String.format(LUA_TABLE_ENTRY_FORMAT, k, map2LuaTable((Map<String, ?>) v)));
            } else if (v instanceof List<?>) {
                list.add(String.format(LUA_TABLE_ENTRY_FORMAT, k, array2LuaArray((List<?>) v)));
            }
        });
        return String.format("{%s}", String.join(",", list));
    }

    public static String array2LuaArray(List<?> array) {
        List<String> strs = new ArrayList<>();
        for (Object o : array) {
            if (o instanceof String) {
                String str = "\"" + ((String) o).replace("\"", "\\\"") + "\"";
                strs.add(str);
            } else if (o instanceof Integer || o instanceof Long || o instanceof Byte || o instanceof Short) {
                strs.add(o.toString());
            } else if (o instanceof Number) {
                strs.add(String.valueOf(((Number) o).doubleValue()));
            } else if (o instanceof Map) {
                strs.add(map2LuaTable((Map<String, ?>) o));
            } else if (o instanceof List<?>) {
                strs.add(array2LuaArray((List<?>) o));
            }
        }
        List<String> entrys = new ArrayList<>();
        for (int i = 0; i < strs.size(); i++) {
            entrys.add(String.format(LUA_ARRAY_ENTRY_FORMAT, i + 1, strs.get(i)));
        }
        return String.format("{%s}", String.join(",", entrys));
    }

    private static Map<String, Object> item2LuaTable(ItemStack item) {
        Map<String, Object> map = new HashMap<>();
        map.put("label", item.getDisplayName());
        map.put("unlocalized", item.getUnlocalizedName());
        map.put("size", item.stackSize);
        map.put("damage", item.getItemDamage());
        map.put("id", Item.itemRegistry.getIDForObject(item.getItem()));
        map.put("name", Item.itemRegistry.getNameForObject(item.getItem()));
        return map;
    }
}
