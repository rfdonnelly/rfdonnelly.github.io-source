---
title: "Rust Iterator Adapters"
date: 2019-12-23T08:00:00-08:00
draft: true
---

Iterator adapters are functions which take an `Iterator` and return another `Iterator`.
Common iterator adapters include `map`, `take`, and `filter`.

The Rust documentation defines iterator adapters but does describe how to implement one.
More specifically, we want to add additional adapters to the `Iterator` trait.
The `itertools` crate adds many additional iterator adapters to `Iterator`.
But what if it doesn't provide what you want?

First we need to define a new iterator.
Then we'll create an adapter for it.

In this example we'll create an iterator that repeats items `n` times.

```rust
pub struct Repeat<I: Iterator> {
    /// The underlying (or input) iterator
    iter: I,
    /// The item to repeat
    item: Option<I::Item>,
    /// The number of times to repeat
    n: usize,
    /// Count down of the repititions
    counter: usize,
}
```

Now we implement `Iterator` for the `Repeat` struct.

```rust
impl<I> Iterator for Repeat<I>
where
    I: Iterator,
    // Item needs to be Copy since we return the same item multiple times
    I::Item: Copy,
{
    type Item = I::Item;

    fn next(&mut self) -> Option<Self::Item> {
        if self.counter == 0 {
            self.counter = self.n;
            self.item = self.iter.next();
        } else {
            self.counter -= 1;
        }

        match self.item {
            Some(item) => Some(item),
            None => None,
        }
    }
}
```

Now we have our new iterator but using it is not very ergonomic.
To use it, we must know the right default values to use.
Let's improve the ergonomics by adding a constructor.

```rust
impl<I> Repeat<I>
where
    I: Iterator,
{
    fn new(iter: I, n: usize) -> Self {
        Self {
            iter,
            item: None,
            n: n - 1,
            counter: 0,
        }
    }
}
```

This abstracts the defaults from the user but using it is not idiomatic.
We can make it idiomatic by enabling function chaining with an iterator adapter.
To do this, we need to define a new trait that extends the `Iterator` trait.

```rust
pub trait RepeatIteratorAdapter
where
    Self: Sized + Iterator,
{
    fn repeat(self, n: usize) -> Repeat<Self>;
}
```

Now we need to implement this new trait for all iterators.

```rust
impl<I> RepeatIteratorAdapter for I
where
    I: Iterator,
{
    fn repeat(self, n: usize) -> Repeat<Self> {
        Repeat::new(self, n)
    }
}
```

Finally, we can use our new adapter.

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn repeat_iterator_adapter() {
        let input = vec![-1, 0, 1];
        let expected = vec![-1, -1, -1, 0, 0, 0, 1, 1, 1];
        let actual: Vec<i32> = input
            .into_iter()
            .repeat(3)
            .collect();
        assert_eq!(actual, expected);
    }
}
```
