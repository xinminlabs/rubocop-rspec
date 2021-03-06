# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if there is an empty line after the last let block.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #   let(:something) { other }
      #   it { does_something }
      #
      #   # good
      #   let(:foo) { bar }
      #   let(:something) { other }
      #
      #   it { does_something }
      class EmptyLineAfterFinalLet < Cop
        MSG = 'Add an empty line after the last `let` block.'.freeze

        def_node_matcher :let?, '(block $(send nil? {:let :let!} ...) args ...)'

        def on_block(node)
          return unless example_group_with_body?(node)

          latest_let = node.body.child_nodes.select { |child| let?(child) }.last

          return if latest_let.nil?
          return if latest_let.equal?(node.body.children.last)

          no_new_line_after(latest_let) do
            add_offense(latest_let, location: :expression)
          end
        end

        def autocorrect(node)
          loc = last_node_loc(node)
          ->(corrector) { corrector.insert_after(loc.end, "\n") }
        end

        private

        def no_new_line_after(node)
          loc = last_node_loc(node)

          next_line = processed_source[loc.line]

          yield unless next_line.blank?
        end

        def last_node_loc(node)
          last_line = node.loc.end.line
          heredoc_line(node) do |loc|
            return loc if loc.line > last_line
          end
          node.loc.end
        end

        def heredoc_line(node, &block)
          yield node.loc.heredoc_end if node.loc.respond_to?(:heredoc_end)

          node.each_child_node { |child| heredoc_line(child, &block) }
        end
      end
    end
  end
end
