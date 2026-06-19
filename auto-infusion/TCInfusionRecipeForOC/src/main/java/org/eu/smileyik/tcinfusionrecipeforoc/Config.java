package org.eu.smileyik.tcinfusionrecipeforoc;

import java.io.File;

import net.minecraftforge.common.config.Configuration;

public class Config {

    public static String savePath = "tc-infusion-recipes";

    public static void synchronizeConfiguration(File configFile) {
        Configuration configuration = new Configuration(configFile);

        savePath = configuration.getString("greeting", Configuration.CATEGORY_GENERAL, savePath, "How shall I greet?");

        if (configuration.hasChanged()) {
            configuration.save();
        }
    }
}
