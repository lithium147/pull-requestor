package com.hsbc.contact;

import java.util.Arrays;
import java.util.function.Consumer;

import static org.assertj.core.api.Assertions.assertThat;

public abstract class MatchingConsumer<T> implements Consumer<T> {

    public static <T> Consumer<T> allOf(Consumer<T>... items) {
        return t -> Arrays.stream(items)
                .forEach(i -> i.accept(t));
    }

    @Override
    public void accept(T t) {
        Description description = new StringDescription();
        description.appendText("expecting ");
        describeTo(description);
        description.appendText(" but ");
        describeMismatchSafely(t, description);
        assertThat(matchesSafely(t))
                .withFailMessage(description.toString())
                .isTrue();
    }

//    Description description = new StringDescription();
//            description.appendText(reason)
//            .appendText(System.lineSeparator())
//            .appendText("Expected: ")
//                       .appendDescriptionOf(matcher)
//                       .appendText(System.lineSeparator())
//            .appendText("     but: ");
//            matcher.describeMismatch(actual, description);


//            mismatchDescription.appendText("item " + nextMatchIx + ": ");
//            matcher.describeMismatch(item, mismatchDescription);

    protected abstract boolean matchesSafely(T item);

    public abstract void describeTo(Description description);

    protected abstract void describeMismatchSafely(T item, Description mismatchDescription);
}
