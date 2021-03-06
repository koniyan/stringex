# encoding: UTF-8

module Stringex
  module StringExtensions
    DEFAULT_CHARACTER_CONVERSIONS =
      {
        :and           => "and",
        :number        => "number",
        :at            => "at",
        :dot           => '\1 dot \2',
        :dollars       => '\1 dollars',
        :dollars_cents => '\1 dollars \2 cents',
        :pounds        => '\1 pounds',
        :pounds_pence  => '\1 pounds \2 pence',
        :euros         => '\1 euros',
        :euros_cents   => '\1 euros \2 cents',
        :yen           => '\1 yen',
        :star          => "star",
        :percent       => "percent",
        :equals        => "equals",
        :plus          => "plus",
        :divide        => "divide",
        :degrees       => "degrees",
        :ellipsis      => "dot dot dot",
        :slash         => "slash"
      }

    DEFAULT_HTML_ENTITY_CONVERSIONS =
      {
        :double_quote => "\"",
        :single_quote => "'",
        :ellipsis     => "...",
        :en_dash      => "-",
        :em_dash      => "--",
        :times        => "x",
        :gt           => ">",
        :lt           => "<",
        :trade        => "(tm)",
        :reg          => "(r)",
        :copy         => "(c)",
        :amp          => "and",
        :nbsp         => " ",
        :cent         => " cent",
        :pound        => " pound",
        :frac14       => "one fourth",
        :frac12       => "half",
        :frac34       => "three fourths",
        :divide       => "divide",
        :deg          => " degrees "
      }

    DEFAULT_VULGAR_FRACTION_CONVERSIONS =
      {
        :one_fourth    => "one fourth",
        :half          => "half",
        :three_fourths => "three fourths",
        :one_third     => "one third",
        :two_thirds    => "two thirds",
        :one_fifth     => "one fifth",
        :two_fifths    => "two fifths",
        :three_fifths  => "three fifths",
        :four_fifths   => "four fifths",
        :one_sixth     => "one sixth",
        :five_sixths   => "five sixths",
        :one_eighth    => "one eighth",
        :three_eighths => "three eighths",
        :five_eighths  => "five eighths",
        :seven_eighths => "seven eighths"
      }

    # These methods are all included into the String class.
    module PublicInstanceMethods
      # Removes specified character from the beginning and/or end of the string and then performs
      # <tt>String#squeeze(character)</tt>, condensing runs of the character within the string.
      #
      # Note: This method has been superceded by ActiveSupport's squish method.
      def collapse(character = " ")
        sub(/^#{character}*/, "").sub(/#{character}*$/, "").squeeze(character)
      end

      # Converts HTML entities into the respective non-accented letters. Examples:
      #
      #   "&aacute;".convert_accented_entities # => "a"
      #   "&ccedil;".convert_accented_entities # => "c"
      #   "&egrave;".convert_accented_entities # => "e"
      #   "&icirc;".convert_accented_entities # => "i"
      #   "&oslash;".convert_accented_entities # => "o"
      #   "&uuml;".convert_accented_entities # => "u"
      #
      # Note: This does not do any conversion of Unicode/ASCII accented-characters. For that
      # functionality please use <tt>to_ascii</tt>.
      def convert_accented_html_entities
        gsub(/&([A-Za-z])(grave|acute|circ|tilde|uml|ring|cedil|slash);/, '\1').strip
      end

      # Converts various common plaintext characters to a more URI-friendly representation.
      # Examples:
      #
      #   "foo & bar".convert_misc_characters # => "foo and bar"
      #   "Chanel #9".convert_misc_characters # => "Chanel number nine"
      #   "user@host".convert_misc_characters # => "user at host"
      #   "google.com".convert_misc_characters # => "google dot com"
      #   "$10".convert_misc_characters # => "10 dollars"
      #   "*69".convert_misc_characters # => "star 69"
      #   "100%".convert_misc_characters # => "100 percent"
      #   "windows/mac/linux".convert_misc_characters # => "windows slash mac slash linux"
      #
      # It allows localization of conversions so you can use it to convert characters into your own language.
      # Example:
      #
      #   I18n.backend.store_translations :de, { :stringex => { :characters => { :and => "und" } } }
      #   I18n.locale = :de
      #   "ich & dich".convert_misc_characters # => "ich und dich"
      #
      # Note: Because this method will convert any & symbols to the string "and",
      # you should run any methods which convert HTML entities (convert_accented_html_entities and convert_miscellaneous_html_entities)
      # before running this method.
      def convert_miscellaneous_characters(options = {})
        options = stringex_default_options.merge(options)

        dummy = dup.gsub(/\s*\.{3,}\s*/, " #{stringex_translate_character(:ellipsis)} ") # Catch ellipses before single dot rule!
        # Special rules for money
        {
          /(?:\s|^)\$(\d+)\.(\d+)(?:\s|$)/ => :dollars_cents,
          /(?:\s|^)£(\d+)\.(\d+)(?:\s|$)/u => :pounds_pence,
          /(?:\s|^)€(\d+)\.(\d+)(?:\s|$)/u => :euros_cents,
        }.each do |found, key|
          replaced = stringex_translate_character(key)
          dummy.gsub!(found, " #{replaced} ")
        end
        # Special rules for abbreviations
        dummy.gsub!(/(\s|^)([[:alpha:]](\.[[:alpha:]])+(\.?)[[:alpha:]]*(\s|$))/) do |x|
          x.gsub(".", "")
        end
        # Back to normal rules

        misc_characters =
        {
          /\s*&\s*/                 => :and,
          /\s*#/                    => :number,
          /\s*@\s*/                 => :at,
          /(\S|^)\.(\S)/            => :dot,
          /(?:\s|^)\$(\d*)(?:\s|$)/ => :dollars,
          /(?:\s|^)£(\d*)(?:\s|$)/u => :pounds,
          /(?:\s|^)€(\d*)(?:\s|$)/u => :euros,
          /(?:\s|^)¥(\d*)(?:\s|$)/u => :yen,
          /\s*\*\s*/                => :star,
          /\s*%\s*/                 => :percent,
          /\s*=\s*/                 => :equals,
          /\s*\+\s*/                => :plus,
          /\s*÷\s*/                 => :divide,
          /\s*°\s*/                 => :degrees
        }
        misc_characters[/\s*(\\|\/|／)\s*/] = :slash unless options[:allow_slash]
        misc_characters.each do |found, key|
          replaced = stringex_translate_character(key)
          replaced = " #{replaced} " unless key == :dot
          dummy.gsub!(found, replaced)
        end
        dummy = dummy.gsub(/(^|[[:alpha:]])'|`([[:alpha:]]|$)/, '\1\2').gsub(/[\.,:;()\[\]\/\?!\^'ʼ"_\|]/, " ").strip
      end

      # Converts HTML entities (taken from common Textile/RedCloth formattings) into plain text formats.
      #
      # Note: This isn't an attempt at complete conversion of HTML entities, just those most likely
      # to be generated by Textile.
      def convert_miscellaneous_html_entities
        dummy = dup
        {
          "#822[01]"      => :double_quote,
          "#821[67]"      => :single_quote,
          "#8230"         => :ellipsis,
          "#8211"         => :en_dash,
          "#8212"         => :em_dash,
          "#215"          => :times,
          "gt"            => :gt,
          "lt"            => :lt,
          "(#8482|trade)" => :trade,
          "(#174|reg)"    => :reg,
          "(#169|copy)"   => :copy,
          "(#38|amp)"     => :amp,
          "nbsp"          => :nbsp,
          "(#162|cent)"   => :cent,
          "(#163|pound)"  => :pound,
          "(#188|frac14)" => :frac14,
          "(#189|frac12)" => :frac12,
          "(#190|frac34)" => :frac34,
          "(#247|divide)" => :divide,
          "(#176|deg)"    => :deg
        }.each do |textiled, key|
          normal = stringex_translate_html_entitity(key)
          dummy.gsub!(/&#{textiled};/, normal)
        end
        dummy.gsub(/&[^;]+;/, "").strip
      end

      # Converts MS Word 'smart punctuation' to ASCII
      #
      def convert_smart_punctuation
        dummy = dup
        {

          "(“|”|\302\223|\302\224|\303\222|\303\223)" => '"',
          "(‘|’|\302\221|\302\222|\303\225)" => "'",
          "…" => "...",
        }.each do |smart, normal|
          dummy.gsub!(/#{smart}/, normal)
        end
        dummy.strip
      end

      # Converts vulgar fractions from supported HTML entities and Unicode to plain text formats.
      def convert_vulgar_fractions
        dummy = dup
        {
          "(&#188;|&frac14;|¼)" => :one_fourth,
          "(&#189;|&frac12;|½)" => :half,
          "(&#190;|&frac34;|¾)" => :three_fourths,
          "(&#8531;|⅓)"         => :one_third,
          "(&#8532;|⅔)"         => :two_thirds,
          "(&#8533;|⅕)"         => :one_fifth,
          "(&#8534;|⅖)"         => :two_fifths,
          "(&#8535;|⅗)"         => :three_fifths,
          "(&#8536;|⅘)"         => :four_fifths,
          "(&#8537;|⅙)"         => :one_sixth,
          "(&#8538;|⅚)"         => :five_sixths,
          "(&#8539;|⅛)"         => :one_eighth,
          "(&#8540;|⅜)"         => :three_eighths,
          "(&#8541;|⅝)"         => :five_eighths,
          "(&#8542;|⅞)"         => :seven_eighths
        }.each do |textiled, key|
          normal = stringex_translate_vulgar_fraction(key)
          dummy.gsub!(/#{textiled}/, normal)
        end
        dummy
      end

      # Returns the string limited in size to the value of limit.
      def limit(limit = nil)
        limit.nil? ? self : self[0...limit]
      end

      # Performs multiple text manipulations. Essentially a shortcut for typing them all. View source
      # below to see which methods are run.
      def remove_formatting(options = {})
        strip_html_tags.
          convert_smart_punctuation.
          convert_accented_html_entities.
          convert_vulgar_fractions.
          convert_miscellaneous_html_entities.
          convert_miscellaneous_characters(options).
          to_ascii(options).
          # NOTE: String#to_ascii may convert some Unicode characters to ascii we'd already transliterated
          # so we need to do it again just to be safe
          convert_miscellaneous_characters(options).
          collapse
      end

      # Replace runs of whitespace in string. Defaults to a single space but any replacement
      # string may be specified as an argument. Examples:
      #
      #   "Foo       bar".replace_whitespace # => "Foo bar"
      #   "Foo       bar".replace_whitespace("-") # => "Foo-bar"
      def replace_whitespace(replacement = " ")
        gsub(/\s+/, replacement)
      end

      # Removes HTML tags from text.
      # NOTE: This code is simplified from Tobias Luettke's regular expression in Typo[http://typosphere.org].
      def strip_html_tags(leave_whitespace = false)
        name = /[\w:_-]+/
        value = /([A-Za-z0-9]+|('[^']*?'|"[^"]*?"))/
        attr = /(#{name}(\s*=\s*#{value})?)/
        rx = /<[!\/?\[]?(#{name}|--)(\s+(#{attr}(\s+#{attr})*))?\s*([!\/?\]]+|--)?>/
        (leave_whitespace) ?  gsub(rx, "").strip : gsub(rx, "").gsub(/\s+/, " ").strip
      end

      # Returns the string converted (via Textile/RedCloth) to HTML format
      # or self [with a friendly warning] if Redcloth is not available.
      #
      # Using <tt>:lite</tt> argument will cause RedCloth to not wrap the HTML in a container
      # P element, which is useful behavior for generating header element text, etc.
      # This is roughly equivalent to ActionView's <tt>textilize_without_paragraph</tt>
      # except that it makes RedCloth do all the work instead of just gsubbing the return
      # from RedCloth.
      def to_html(lite_mode = false)
        if defined?(RedCloth)
          if lite_mode
            RedCloth.new(self, [:lite_mode]).to_html
          else
            if self =~ /<pre>/
              RedCloth.new(self).to_html.tr("\t", "")
            else
              RedCloth.new(self).to_html.tr("\t", "").gsub(/\n\n/, "")
            end
          end
        else
          warn "String#to_html was called without RedCloth being successfully required"
          self
        end
      end

      # Create a URI-friendly representation of the string. This is used internally by
      # acts_as_url[link:classes/Stringex/ActsAsUrl/ClassMethods.html#M000012]
      # but can be called manually in order to generate an URI-friendly version of any string.
      def to_url(options = {})
        return self if options[:exclude] && options[:exclude].include?(self)
        options = stringex_default_options.merge(options)
        whitespace_replacement_token = options[:replace_whitespace_with]
        dummy = remove_formatting(options).
                  replace_whitespace(whitespace_replacement_token).
                  collapse("-").
                  limit(options[:limit])
        dummy.downcase! unless options[:force_downcase] == false
        dummy
      end

    private

      def stringex_default_options
        Stringex::Configuration::StringExtensions.default_settings
      end

      def stringex_translate_character(key)
        Localization.translate(:characters, key, :default => DEFAULT_CHARACTER_CONVERSIONS[key])
      end

      def stringex_translate_html_entitity(key)
        Localization.translate(:html_entities, key, :default => DEFAULT_HTML_ENTITY_CONVERSIONS[key])
      end

      def stringex_translate_vulgar_fraction(key)
        Localization.translate(:vulgar_fractions, key, :default => DEFAULT_VULGAR_FRACTION_CONVERSIONS[key])
      end
    end

    # These methods are extended onto the String class itself.
    module PublicClassMethods
      # Returns string of random characters with a length matching the specified limit. Excludes 0
      # to avoid confusion between 0 and O.
      def random(limit)
        strong_alphanumerics = %w{
          a b c d e f g h i j k l m n o p q r s t u v w x y z
          A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
          1 2 3 4 5 6 7 8 9
        }
        Array.new(limit, "").collect{strong_alphanumerics[rand(61)]}.join
      end
    end
  end
end
