/*
 * Copyright (C) 2014 The Android Open Source Project
 * With modifications copyright (C) 2016 Fusetools AS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package fuse.android.graphics;

import android.util.Xml;

import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Parser for font config files.
 *
 * @hide
 */
public class FontListParser {

    public static class Config {
        Config() {
            this(-1, new ArrayList<Family>(), new ArrayList<Alias>());
        }
        Config(int version, List<Family> families, List<Alias> aliases) {
            this.version = version;
            this.families = families;
            this.aliases = aliases;
        }
        public final int version;
        public final List<Family> families;
        public final List<Alias> aliases;

        public void append(Config other) {
            this.families.addAll(other.families);
            this.aliases.addAll(other.aliases);
        }

        public void mixin(Config other) {
            int lastOrder = -1;
            for (Family family : other.families) {
                int order = family.order;
                if (order >= 0) {
                    this.families.add(order, family);
                    lastOrder = order + 1;
                } else {
                    if (lastOrder >= 0) {
                        this.families.add(lastOrder, family);
                        ++lastOrder;
                    } else {
                        this.families.add(family);
                    }
                }
            }
            this.aliases.addAll(other.aliases);
        }
    }

    public static class Font {
        Font(String fontName, int ttcIndex, int weight, boolean isItalic) {
            this.fontName = fontName;
            this.ttcIndex = ttcIndex;
            this.weight = weight;
            this.isItalic = isItalic;
        }
        public final String fontName;
        public final int ttcIndex;
        public final int weight;
        public final boolean isItalic;
    }

    public static class Alias {
        Alias(String name, String toName, int weight) {
            this.name = name;
            this.toName = toName;
            this.weight = weight;
        }

        public final String name;
        public final String toName;
        public final int weight;
    }

    public static class Family {
        public Family(List<String> names, List<Font> fonts, String lang, String variant) {
            this(names, fonts, lang, variant, -1);
        }

        public Family(List<String> names, List<Font> fonts, String lang, String variant, int order) {
            this.names = names;
            this.fonts = fonts;
            this.lang = lang;
            this.variant = variant;
            this.order = order;
        }

        public final List<String> names;
        public final List<Font> fonts;
        public final String lang;
        public final String variant;
        public final int order;
    }

    public static final int NormalWeight = 400;
    public static final int BoldWeight = 700;

    // Dispatches between new and old format
    public static Config getFontConfig()
            throws FileNotFoundException, XmlPullParserException, IOException {
        File newXmlFile = new File("/system/etc/fonts.xml");
        File oldXmlFile = new File("/system/etc/system_fonts.xml");
        File oldFallbackXmlFile = new File("/system/etc/fallback_fonts.xml");
        File oldVendorXmlFile = new File("/vendor/etc/fallback_fonts.xml");

        Config result = new Config();
        if (newXmlFile.exists()) {
            try {
                result = parse(new FileInputStream(newXmlFile.getAbsolutePath()));
            } catch (XmlPullParserException e) {
                // Fall through
            }

            // Version 21 and up doesn't need fallback config
            if (result.version >= 21) {
                return result;
            }
        } else if (oldXmlFile.exists()) {
            result.append(parseOld(new FileInputStream(oldXmlFile.getAbsolutePath())));
        } else {
            throw new FileNotFoundException("No Android font configuration file found");
        }

        Config fallback = new Config();

        if (oldFallbackXmlFile.exists()) {
            fallback.append(parseOld(new FileInputStream(oldFallbackXmlFile.getAbsolutePath())));

            if (oldVendorXmlFile.exists()) {
                fallback.mixin(parseOld(new FileInputStream(oldVendorXmlFile.getAbsolutePath())));
            }
        }

        result.append(fallback);
        return result;
    }

    // ------------------------------------------------------------------------
    // New format (/system/etc/fonts.xml)

    /* Parse fallback list (no names) */
    public static Config parse(InputStream in) throws XmlPullParserException, IOException {
        try {
            XmlPullParser parser = Xml.newPullParser();
            parser.setInput(in, null);
            parser.nextTag();
            return readFamilies(parser);
        } finally {
            in.close();
        }
    }

    private static Config readFamilies(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        parser.require(XmlPullParser.START_TAG, null, "familyset");
        String versionString = parser.getAttributeValue(null, "version");
        int version = versionString == null ? -1 : Integer.parseInt(versionString);
        List<Family> families = new ArrayList<Family>();
        List<Alias> aliases = new ArrayList<Alias>();
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("family")) {
                families.add(readFamily(parser));
            } else if (parser.getName().equals("alias")) {
                aliases.add(readAlias(parser));
            } else {
                skip(parser);
            }
        }
        return new Config(version, families, aliases);
    }

    private static Family readFamily(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        String name = parser.getAttributeValue(null, "name");
        String lang = parser.getAttributeValue(null, "lang");
        String variant = parser.getAttributeValue(null, "variant");
        List<Font> fonts = new ArrayList<Font>();
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("font")) {
                fonts.add(readFont(parser));
            } else {
                skip(parser);
            }
        }
        List<String> names = new ArrayList<String>();
        if (name != null)
            names.add(name);
        return new Family(names, fonts, lang, variant);
    }

    /** Matches leading and trailing XML whitespace. */
    private static final Pattern FILENAME_WHITESPACE_PATTERN =
            Pattern.compile("^[ \\n\\r\\t]+|[ \\n\\r\\t]+$");

    private static Font readFont(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        String indexStr = parser.getAttributeValue(null, "index");
        int index = indexStr == null ? 0 : Integer.parseInt(indexStr);
        String weightStr = parser.getAttributeValue(null, "weight");
        int weight = weightStr == null ? 400 : Integer.parseInt(weightStr);
        boolean isItalic = "italic".equals(parser.getAttributeValue(null, "style"));
        StringBuilder filename = new StringBuilder();
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() == XmlPullParser.TEXT) {
                filename.append(parser.getText());
            }
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            skip(parser);
        }
        String sanitizedName = FILENAME_WHITESPACE_PATTERN.matcher(filename).replaceAll("");
        return new Font(absoluteFontPath(sanitizedName), index, weight, isItalic);
    }

    private static Alias readAlias(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        String name = parser.getAttributeValue(null, "name");
        String toName = parser.getAttributeValue(null, "to");
        String weightStr = parser.getAttributeValue(null, "weight");
        int weight = weightStr == null ? NormalWeight : Integer.parseInt(weightStr);
        skip(parser);  // alias tag is empty, ignore any contents and consume end tag
        return new Alias(name, toName, weight);
    }

    // ------------------------------------------------------------------------
    // Old (Jellybean and earlier) format (/system/etc/{system_fonts.xml,fallback_fonts.xml}, etc)

    public static Config parseOld(InputStream in) throws XmlPullParserException, IOException {
        try {
            XmlPullParser parser = Xml.newPullParser();
            parser.setInput(in, null);
            parser.nextTag();
            return readOldFamilies(parser);
        } finally {
            in.close();
        }
    }

    private static Config readOldFamilies(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        parser.require(XmlPullParser.START_TAG, null, "familyset");
        String versionString = parser.getAttributeValue(null, "version");
        int version = versionString == null ? -1 : Integer.parseInt(versionString);
        List<Family> families = new ArrayList<Family>();
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("family")) {
                families.add(readOldFamily(parser));
            } else {
                skip(parser);
            }
        }
        return new Config(version, families, new ArrayList<Alias>());
    }

    private static Family readOldFamily(XmlPullParser parser)
            throws XmlPullParserException, IOException {
        List<String> names = new ArrayList<String>();
        List<String> files = new ArrayList<String>();
        String orderString = parser.getAttributeValue(null, "order");
        int order = orderString == null ? -1 : Integer.parseInt(orderString);

        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("nameset")) {
                readNameSet(parser, names);
            }
            else if (parser.getName().equals("fileset")) {
                readFileSet(parser, files);
            } else {
                skip(parser);
            }
        }

        List<Font> fonts = createOldFontList(files);
        return new Family(names, fonts, null, null, order);
    }

    private static List<Font> createOldFontList(List<String> files)
    {
        List<Font> result = new ArrayList<Font>();
        int len = Math.min(files.size(), 4);
        for (int i = 0; i < len; ++i) {
            // The fonts are listed in order: regular, bold, italic, bold-italic
            int weight = i % 2 == 0 ? NormalWeight : BoldWeight;
            boolean isItalic = i >= 2;
            result.add(new Font(files.get(i), 0, weight, isItalic));
        }
        return result;
    }

    private static void readNameSet(XmlPullParser parser, List<String> names)
            throws XmlPullParserException, IOException {
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("name")) {
                String name = parser.nextText();
                names.add(name);
            } else {
                skip(parser);
            }
        }
    }

    private static void readFileSet(XmlPullParser parser, List<String> files)
            throws XmlPullParserException, IOException {
        while (parser.next() != XmlPullParser.END_TAG) {
            if (parser.getEventType() != XmlPullParser.START_TAG) continue;
            if (parser.getName().equals("file")) {
                String file = parser.nextText();
                files.add(absoluteFontPath(file));
            } else {
                skip(parser);
            }
        }
    }

    // ------------------------------------------------------------------------
    // Helpers

    private static void skip(XmlPullParser parser) throws XmlPullParserException, IOException {
        int depth = 1;
        while (depth > 0) {
            switch (parser.next()) {
            case XmlPullParser.START_TAG:
                depth++;
                break;
            case XmlPullParser.END_TAG:
                depth--;
                break;
            }
        }
    }

    private static String absoluteFontPath(String relative) {
            return "/system/fonts/" + relative;
    }
}
