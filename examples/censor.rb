require_relative '../fuzzy_text'

def censor(text)
  ::FuzzyText.new(text, "very important thing")
             .matches
             .sort { |a, b| b.size <=> a.size }
             .each { |phrase| text.gsub!(phrase, '[XXX]') }
  text
end

text = "Lorem ipsum dolor sit amet, very importanty thing adipiscing elit. Cras tempus nec mauris id iaculis. Mauris consequat volutpat sem, non convallis odio tristique sed. Suspendisse tempor sem nulla, ac lacinia augue vehicula ut. Curabitur consectetur lectus ut nunc auctor rhoncus. In varius vehicula sapien at mattis. In et sodales nibh. Vestibulum a justo ac dui eleifend dapibus. Sed laoreet blandit quam et laoreet. Suspendisse luctus mi sit amet bibendum accumsan. Suspendisse egestas leo id massa tempor sodales eget non purus. Donec id dolor libero. Nunc pharetra ac arcu nec consectetur.
In sodales very important thing cursus, a feugiat nunc pharetra. Morbi dictum nulla facilisis ipsum blandit venenatis. In libero nibh, very importante thingy congue, faucibus id elit. Aliquam ut neque et nunc tincidunt dictum. Quisque vulputate ultrices aliquet. Vivamus laoreet blandit purus, at accumsan sapien fermentum ut. Maecenas eget nunc eu nisi tristique venenatis eget ut ipsum. Vivamus consectetur dui ut rhoncus ultricies. Praesent ut arcu tincidunt, iaculis ex sed, consectetur magna. Proin blandit scelerisque elementum.
Etiam a tincidunt enim, non luctus diam. Sed verys important thing. Mauris venenatis felis in consequat fermentum. Pellentesque lectus enim, dignissim vitae elit non, volutpat vehicula lorem. Duis tellus ipsum, vehicula eu rutrum sed, venenatis vel magna. Sed nisl felis, placerat sit amet est quis, maximus viverra erat. Aliquam lobortis vestibulum commodo. Phasellus bibendum rutrum euismod. Vestibulum commodo dolor sed sollicitudin lobortis. Curabitur nec eros enim. Aliquam ut turpis non nisi feugiat elementum. Quisque sodales commodo lobortis."

puts censor(text)
