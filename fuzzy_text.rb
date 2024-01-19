require('fuzzystringmatch')

class FuzzyText
  JAROW = ::FuzzyStringMatch::JaroWinkler.create(:native)

  attr_reader :words, :needle

  def initialize(text, needle)
    @words = text.to_s.strip.split(' ')
    @needle = needle.to_s.strip
    @needle_for_similarity = @needle.downcase.gsub(/[\s,\.\-\!\?]+/, '')

    @hash = {}
  end

  def matches
    (fuzzy_match_search + reverse_search).uniq
  end

  private

  attr_reader :needle_for_similarity

  def fuzzy_match_search
    # Search the text for phrases similar to the needle
    # Example:
    #   needle = Peter Longman And Company From Texas
    #   find phrases like "Peter Longman & Company From Texas"

    fuzzy_match_results
      .map { |phrase| best_subphrase(phrase) }
      .map { |phrase| strip_decorators(phrase) }
      .reject(&:nil?)
      .reject(&:empty?)
      .uniq
      .select { |phrase| similarity_of(phrase) > 0.9 }
  end

  def fuzzy_match_results
    # Divide words into phrases of different sizes
    # Phrase size vary from 1 word to phrases with more spaces than in needle
    # Longer phrases add complexity to the task but may catch misspelling or extra spaces in text
    max_size = needle.count(' ') + 2

    (0..max_size).flat_map { |size| fuzzy_match_results_by_size(size + 1) }
                 .uniq
                 .sort { |a, b| b[1] <=> a[1] }
  end

  def fuzzy_match_results_by_size(size)
    # Divide words into phrases of "size" length
    # Check if phrase is similar enough to the given needle
    # Map and return the similar phrases

    words.each_with_index.map do |_, index|
      index_end = index + size
      phrase = strip_decorators(
        words[index...index_end].join(' ')
      )

      phrase if similarity_of(phrase) > 0.9
    end.compact
  end

  def best_subphrase(phrase)
    # Given a phrase, find a subphrase which matches the needle better
    # Example:
    #   text = "You have to say that Norton Rose Fulbright is a global law firm"
    #   needle = "Norton Rose Fulbright McAlister & Co"
    #   phrase = "Norton Rose Fulbright is a global" - would be one of fuzzy-match search outputs
    #
    #   goal: determine the best subphrase, in this case - "Norton Rose Fulbright"
    #
    # Algorithm:
    #   0. Return phrase if a subphrase cannot be created (contains only 1 word)
    #   1. Create 2 subphrases by cutting of the first or the last word of the phrase
    #   2. If the subphrase without the first word is more similar to the needle, then return its
    #      best subphrase (recursion)
    #   3. If the subphrase without the last word is more similar to the needle, then return its
    #      best subphrase (recursion)
    #   4. If the phrase is more similar to the needle, return phrase
    return phrase if phrase.count(' ').zero?

    phrase_array = phrase.split(' ')
    chop_left = strip_decorators(phrase_array[1..-1].join(' '))
    chop_right = strip_decorators(phrase_array[0..-2].join(' '))

    if similarity_of(phrase) > similarity_of(chop_left) &&
       similarity_of(phrase) > similarity_of(chop_right)
      phrase
    elsif similarity_of(chop_left) > similarity_of(phrase)
      best_subphrase(chop_left)
    else
      best_subphrase(chop_right)
    end
  end

  def similarity_of(phrase)
    # Define similarity of a phrase by comparing with the given needle
    # The needle and the phrase are filtered to remove spaces, and punctuation
    # Results are cached for efficiency
    @hash[phrase] ||= begin
      phrase_for_similarity = phrase.downcase.gsub(/[\s,\.\-\!\?]+/, '')
      JAROW.getDistance(phrase_for_similarity, needle_for_similarity)
    end
  end

  def strip_decorators(phrase)
    # Needle may be included with punctuation or saxon genitive ('s) which are never
    # a part of a needle
    # Strip such characters to achieve better results
    reg_end = Regexp.new(/([\!\?\.,’'\-]|('s)|(’s))+$/)
    reg_beg = Regexp.new(/^[\!\?\.,’'\-]+/)

    phrase = chomp_common_words(phrase)
    phrase.sub(reg_beg, '').sub(reg_end, '')
  end

  def chomp_common_words(phrase)
    # Fuzzy text matching often return results with the needle + a common word
    # Listed common words are never a part of the searched needle
    # Strip common words to achieve better results
    %w(is are was were have been the a).each do |word|
      if phrase.end_with?(" #{word}")
        phrase = phrase
                 .strip
                 .chomp(" #{word}")
      end

      next unless phrase.start_with?("#{word} ")

      phrase = phrase
               .reverse
               .chomp("#{word} ".reverse)
               .reverse
               .strip
    end

    phrase.strip
  end

  def reverse_search
    # Search for smaller substrings of the needle
    # Example:
    #   needle = Peter Longman And Company From Texas
    #   find phrases like "Peter Longman", "Longman And Company"
    max_size = needle.count(' ') - 1
    (2..max_size).flat_map { |size| reverse_search_results_by_size(size) }
                 .uniq
                 .reject { |a| a.size < 2 }
                 .sort { |a, b| b[1] <=> a[1] }
  end

  def reverse_search_results_by_size(size)
    # Divide words into phrases of "size" length
    # Check if the needle contains such a phrase
    # assumption:
    #   needle does not contain common words, a phrase of 2 random common words will never exist
    #   in a needle
    words.each_with_index.map do |_, index|
      index_end = index + size

      phrase = words[index...index_end].join(' ')
      phrase if @needle.include?(phrase)
    end.compact
  end
end
