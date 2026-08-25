import Foundation

/// Languages supported by the `lang` parameter of the IP2Location.io Lookup API.
///
/// Values are ISO 639-1 codes. The translation only applies to the continent,
/// country, region and city names, and is only available on the **Plus** and
/// **Security** plans.
public enum IP2Language: String, CaseIterable, Sendable {
    case arabic = "ar"
    case czech = "cs"
    case danish = "da"
    case german = "de"
    case english = "en"
    case spanish = "es"
    case estonian = "et"
    case finnish = "fi"
    case french = "fr"
    case irish = "ga"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case malay = "ms"
    case dutch = "nl"
    case portuguese = "pt"
    case russian = "ru"
    case swedish = "sv"
    case turkish = "tr"
    case vietnamese = "vi"
    case chineseSimplified = "zh-cn"
    case chineseTraditional = "zh-tw"
}
