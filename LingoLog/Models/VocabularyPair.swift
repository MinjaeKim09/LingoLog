import Foundation

/// The side of a vocabulary pair that the user is currently typing.
enum VocabularyInputSide: String, Equatable {
    case learningLanguage
    case meaningLanguage
}

/// A vocabulary pair normalized for storage, independent of translation direction.
///
/// `term` is always in `learningLanguageCode`; `meaning` is always in
/// `meaningLanguageCode`. This invariant lets stories and quizzes use the pair without
/// needing to know which side the user originally entered.
struct NormalizedVocabularyPair: Equatable {
    let term: String
    let meaning: String
    let learningLanguageCode: String
    let meaningLanguageCode: String

    static func make(
        input: String,
        translatedText: String,
        learningLanguageCode: String,
        meaningLanguageCode: String,
        inputSide: VocabularyInputSide
    ) -> NormalizedVocabularyPair? {
        let input = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let translatedText = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty,
              !translatedText.isEmpty,
              learningLanguageCode != meaningLanguageCode else {
            return nil
        }

        switch inputSide {
        case .learningLanguage:
            return NormalizedVocabularyPair(
                term: input,
                meaning: translatedText,
                learningLanguageCode: learningLanguageCode,
                meaningLanguageCode: meaningLanguageCode
            )
        case .meaningLanguage:
            return NormalizedVocabularyPair(
                term: translatedText,
                meaning: input,
                learningLanguageCode: learningLanguageCode,
                meaningLanguageCode: meaningLanguageCode
            )
        }
    }
}
