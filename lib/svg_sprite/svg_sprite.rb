# frozen_string_literal: true

module SvgSprite
  SVG_ICONS ||= Set.new([
    "adjust",
    "address-book",
    "ambulance",
    "anchor",
    "angle-double-down",
    "angle-double-up",
    "angle-double-right",
    "angle-double-left",
    "angle-down",
    "angle-right",
    "angle-up",
    "archive",
    "arrow-down",
    "arrow-left",
    "arrow-up",
    "arrows-alt-h",
    "arrows-alt-v",
    "at",
    "asterisk",
    "backward",
    "ban",
    "bars",
    "bed",
    "bell",
    "bell-slash",
    "bold",
    "book",
    "book-reader",
    "bookmark",
    "briefcase",
    "calendar-alt",
    "caret-down",
    "caret-left",
    "caret-right",
    "caret-up",
    "certificate",
    "chart-bar",
    "chart-pie",
    "check",
    "check-circle",
    "check-square",
    "chevron-down",
    "chevron-left",
    "chevron-right",
    "chevron-up",
    "circle",
    "code",
    "cog",
    "columns",
    "comment",
    "compress",
    "copy",
    "crosshairs",
    "cube",
    "desktop",
    "discourse-amazon",
    "discourse-bell-exclamation",
    "discourse-bell-one",
    "discourse-bell-slash",
    "discourse-bookmark-clock",
    "discourse-compress",
    "discourse-expand",
    "download",
    "ellipsis-h",
    "ellipsis-v",
    "emoji-icon",
    "envelope",
    "envelope-square",
    "exchange-alt",
    "exclamation-circle",
    "exclamation-triangle",
    "external-link-alt",
    "fab-android",
    "fab-apple",
    "fab-chrome",
    "fab-discord",
    "fab-discourse",
    "fab-facebook-square",
    "fab-facebook",
    "fab-github",
    "fab-instagram",
    "fab-linux",
    "fab-twitter",
    "fab-twitter-square",
    "fab-wikipedia-w",
    "fab-windows",
    "far-bell",
    "far-bell-slash",
    "far-calendar-plus",
    "far-chart-bar",
    "far-check-square",
    "far-circle",
    "far-clipboard",
    "far-clock",
    "far-comment",
    "far-comments",
    "far-copyright",
    "far-dot-circle",
    "far-edit",
    "far-envelope",
    "far-eye",
    "far-eye-slash",
    "far-file-alt",
    "far-frown",
    "far-heart",
    "far-image",
    "far-list-alt",
    "far-meh",
    "far-moon",
    "far-smile",
    "far-square",
    "far-star",
    "far-sun",
    "far-thumbs-down",
    "far-thumbs-up",
    "far-trash-alt",
    "fast-backward",
    "fast-forward",
    "file",
    "file-alt",
    "filter",
    "flag",
    "folder",
    "folder-open",
    "forward",
    "gavel",
    "globe",
    "globe-americas",
    "hand-point-right",
    "hands-helping",
    "heading",
    "heart",
    "history",
    "home",
    "hourglass-start",
    "id-card",
    "info-circle",
    "italic",
    "key",
    "link",
    "list",
    "list-ol",
    "list-ul",
    "lock",
    "magic",
    "map-marker-alt",
    "microphone-slash",
    "minus",
    "minus-circle",
    "mobile-alt",
    "moon",
    "paint-brush",
    "paper-plane",
    "pause",
    "pencil-alt",
    "play",
    "plug",
    "plus",
    "plus-circle",
    "plus-square",
    "power-off",
    "puzzle-piece",
    "question",
    "question-circle",
    "quote-left",
    "quote-right",
    "random",
    "redo",
    "reply",
    "rocket",
    "search",
    "share",
    "shield-alt",
    "shower",
    "sign-in-alt",
    "sign-out-alt",
    "signal",
    "star",
    "step-backward",
    "step-forward",
    "stopwatch",
    "stream",
    "sync-alt",
    "sync",
    "table",
    "tag",
    "tasks",
    "thermometer-three-quarters",
    "thumbs-down",
    "thumbs-up",
    "thumbtack",
    "times",
    "times-circle",
    "toggle-off",
    "toggle-on",
    "trash-alt",
    "tv",
    "undo",
    "unlink",
    "unlock",
    "unlock-alt",
    "upload",
    "user",
    "user-edit",
    "user-plus",
    "user-secret",
    "user-shield",
    "user-times",
    "users",
    "wrench",
    "spinner"
  ])

  FA_ICON_MAP = { 'far fa-' => 'far-', 'fab fa-' => 'fab-', 'fas fa-' => '', 'fa-' => '' }

  CORE_SVG_SPRITES = Dir.glob("#{Rails.root}/vendor/assets/svg-icons/**/*.svg")

  THEME_SPRITE_VAR_NAME = "icons-sprite"

  def self.preload
    settings_icons
    group_icons
    badge_icons
  end

  def self.custom_svg_sprites(theme_ids = [])
    get_set_cache("custom_svg_sprites_#{Theme.transform_ids(theme_ids).join(',')}") do
      custom_sprite_paths = Dir.glob("#{Rails.root}/plugins/*/svg-icons/*.svg")

      if theme_ids.present?
        ThemeField.where(type_id: ThemeField.types[:theme_upload_var], name: THEME_SPRITE_VAR_NAME, theme_id: Theme.transform_ids(theme_ids))
          .pluck(:upload_id).each do |upload_id|

          upload = Upload.find(upload_id) rescue nil

          if Discourse.store.external?
            external_copy = Discourse.store.download(upload) rescue nil
            original_path = external_copy.try(:path)
          else
            original_path = Discourse.store.path_for(upload)
          end

          custom_sprite_paths << original_path if original_path.present?
        end
      end

      custom_sprite_paths
    end
  end

  def self.all_icons(theme_ids = [])
    get_set_cache("icons_#{Theme.transform_ids(theme_ids).join(',')}") do
      Set.new()
        .merge(settings_icons)
        .merge(plugin_icons)
        .merge(badge_icons)
        .merge(group_icons)
        .merge(theme_icons(theme_ids))
        .merge(custom_icons(theme_ids))
        .delete_if { |i| i.blank? || i.include?("/") }
        .map! { |i| process(i.dup) }
        .merge(SVG_ICONS)
        .sort
    end
  end

  def self.version(theme_ids = [])
    get_set_cache("version_#{Theme.transform_ids(theme_ids).join(',')}") do
      Digest::SHA1.hexdigest(bundle(theme_ids))
    end
  end

  def self.path(theme_ids = [])
    "/svg-sprite/#{Discourse.current_hostname}/svg-#{theme_ids&.join(",")}-#{version(theme_ids)}.js"
  end

  def self.expire_cache
    cache&.clear
  end

  def self.sprite_sources(theme_ids)
    sources = CORE_SVG_SPRITES

    if theme_ids.present?
      sources = sources + custom_svg_sprites(theme_ids)
    end

    sources
  end

  def self.core_svgs
    @core_svgs ||= begin
      symbols = {}

      CORE_SVG_SPRITES.each do |filename|
        svg_filename = "#{File.basename(filename, ".svg")}"

        Nokogiri::XML(File.open(filename)) do |config|
          config.options = Nokogiri::XML::ParseOptions::NOBLANKS
        end.css('symbol').each do |sym|
          icon_id = prepare_symbol(sym, svg_filename)
          sym.attributes['id'].value = icon_id
          symbols[icon_id] = sym.to_xml
        end
      end

      symbols
    end
  end

  def self.bundle(theme_ids = [])
    icons = all_icons(theme_ids)

    svg_subset = """<!--
Discourse SVG subset of Font Awesome Free by @fontawesome - https://fontawesome.com
License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License)
-->
<svg xmlns='http://www.w3.org/2000/svg' style='display: none;'>
""".dup

    core_svgs.each do |icon_id, sym|
      if icons.include?(icon_id)
        svg_subset << sym
      end
    end

    custom_svg_sprites(theme_ids).each do |fname|
      svg_file = Nokogiri::XML(File.open(fname)) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOBLANKS
      end

      svg_filename = "#{File.basename(fname, ".svg")}"

      svg_file.css("symbol").each do |sym|
        icon_id = prepare_symbol(sym, svg_filename)

        if icons.include? icon_id
          sym.attributes['id'].value = icon_id
          sym.css('title').each(&:remove)
          svg_subset << sym.to_xml
        end
      end
    end

    svg_subset << '</svg>'
  end

  def self.search(searched_icon)
    searched_icon = process(searched_icon.dup)

    sprite_sources([SiteSetting.default_theme_id]).each do |fname|
      svg_file = Nokogiri::XML(File.open(fname))
      svg_filename = "#{File.basename(fname, ".svg")}"

      svg_file.css('symbol').each do |sym|
        icon_id = prepare_symbol(sym, svg_filename)

        if searched_icon == icon_id
          sym.attributes['id'].value = icon_id
          sym.css('title').each(&:remove)
          return sym.to_xml
        end
      end
    end

    false
  end

  def self.icon_picker_search(keyword)
    results = Set.new

    sprite_sources([SiteSetting.default_theme_id]).each do |fname|
      svg_file = Nokogiri::XML(File.open(fname))
      svg_filename = "#{File.basename(fname, ".svg")}"

      svg_file.css('symbol').each do |sym|
        icon_id = prepare_symbol(sym, svg_filename)
        if keyword.empty? || icon_id.include?(keyword)
          sym.attributes['id'].value = icon_id
          sym.css('title').each(&:remove)
          results.add(id: icon_id, symbol: sym.to_xml)
        end
      end
    end

    results.sort_by { |icon| icon[:id] }
  end

  # For use in no_ember .html.erb layouts
  def self.raw_svg(name)
    get_set_cache("raw_svg_#{name}") do
      symbol = search(name)
      break "" unless symbol
      symbol = Nokogiri::XML(symbol).children.first
      symbol.name = "svg"
      <<~HTML
        <svg class="fa d-icon svg-icon svg-node" aria-hidden="true">#{symbol}</svg>
      HTML
    end.html_safe
  end

  def self.theme_sprite_variable_name
    THEME_SPRITE_VAR_NAME
  end

  def self.prepare_symbol(symbol, svg_filename)
    icon_id = symbol.attr('id')

    case svg_filename
    when "regular"
      icon_id = icon_id.prepend('far-')
    when "brands"
      icon_id = icon_id.prepend('fab-')
    end

    icon_id
  end

  def self.settings_icons
    get_set_cache("settings_icons") do
      # includes svg_icon_subset and any settings containing _icon (incl. plugin settings)
      site_setting_icons = []

      SiteSetting.settings_hash.select do |key, value|
        if key.to_s.include?("_icon") && String === value
          site_setting_icons |= value.split('|')
        end
      end

      site_setting_icons
    end
  end

  def self.plugin_icons
    DiscoursePluginRegistry.svg_icons
  end

  def self.badge_icons
    get_set_cache("badge_icons") do
      Badge.pluck(:icon).uniq
    end
  end

  def self.group_icons
    get_set_cache("group_icons") do
      Group.pluck(:flair_icon).uniq
    end
  end

  def self.theme_icons(theme_ids)
    return [] if theme_ids.blank?

    theme_icon_settings = []

    # Need to load full records for default values
    Theme.where(id: Theme.transform_ids(theme_ids)).each do |theme|
      settings = theme.cached_settings.each do |key, value|
        if key.to_s.include?("_icon") && String === value
          theme_icon_settings |= value.split('|')
        end
      end
    end

    theme_icon_settings |= ThemeModifierHelper.new(theme_ids: theme_ids).svg_icons

    theme_icon_settings
  end

  def self.custom_icons(theme_ids)
    # Automatically register icons in sprites added via themes or plugins
    icons = []
    custom_svg_sprites(theme_ids).each do |fname|
      svg_file = Nokogiri::XML(File.open(fname))

      svg_file.css('symbol').each do |sym|
        icons << sym.attributes['id'].value if sym.attributes['id'].present?
      end
    end
    icons
  end

  def self.process(icon_name)
    icon_name = icon_name.strip
    FA_ICON_MAP.each { |k, v| icon_name = icon_name.sub(k, v) }
    icon_name
  end

  def self.get_set_cache(key)
    return cache[key] if cache[key]
    value = yield
    cache.defer_set(key, value)
    value
  end

  def self.cache
    @cache ||= DistributedCache.new('svg_sprite')
  end
end
