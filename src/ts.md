# TypeScript Interview Guide

## Basic TypeScript Syntax & Features

### 1. What are the key differences between TypeScript and JavaScript?
TypeScript is a statically typed superset of JavaScript. It adds types, interfaces, and compile-time type checking, which JavaScript lacks. TypeScript transpiles to plain JavaScript, making it compatible with any JavaScript environment.

### 2. Why do we need TypeScript?
TypeScript helps catch errors at compile time, offers better tooling (autocomplete, refactoring), and ensures more maintainable and scalable code by enforcing strict typing rules.

### 3. What types exist in TypeScript?
TypeScript supports primitive types like string, number, boolean, undefined, null, symbol, and bigint. It also supports complex types like arrays, tuples, enums, any, unknown, void, never, objects, and union and intersection types.

### 4. What is the difference between type and interface?
`type` and `interface` both allow you to define custom types, but `interface` is better suited for defining shapes of objects, while `type` can handle more complex types such as unions and tuples.

```typescript
type CustomType = string | number;

interface User {
  id: number;
  name: string;
}
```

### 5. What is your opinion on JSDoc as an alternative to TypeScript?
JSDoc is a documentation tool that can annotate types in JavaScript, but it doesn't offer the same compile-time safety as TypeScript. JSDoc lacks many features TypeScript has, such as static analysis, which ensures code correctness before execution.

### 6. What are union types in TypeScript? Give an example.
A union type allows a value to be one of several types. It uses the `|` operator to combine types.

```typescript
function printId(id: number | string) {
  console.log(id);
}
```

### 7. How does TypeScript handle type assertions? Why should you use as?
Type assertions (using `as` or the angle bracket syntax) tell the TypeScript compiler that you know the type better than it does. It's used when you're sure about the type but TypeScript cannot infer it correctly.

```typescript
const value: any = "Hello";
const strLength: number = (value as string).length;
```

### 8. What is the difference between the unknown and any types?
`unknown` is safer than `any`. While `any` disables all type-checking, `unknown` forces you to perform type checks before manipulating the value.

```typescript
let data: unknown;
data = "Hello";
if (typeof data === "string") {
  console.log(data.toUpperCase());
}
```

### 9. What is the never type, and when would you use it?
The `never` type represents values that never occur. It's often used for functions that throw errors or infinite loops.

```typescript
function throwError(): never {
  throw new Error("This is an error");
}
```

### 10. What is type narrowing, and how does TypeScript implement it?
Type narrowing occurs when TypeScript reduces the type of a variable to a more specific type using type guards, such as `typeof` or `instanceof`.

```typescript
function padLeft(value: string | number) {
  if (typeof value === "string") {
    return value.padStart(10);
  }
  return value.toString();
}
```

## Advanced Type Features

### 11. What are generics in TypeScript, and how do they contribute to reusability?
Generics allow you to create reusable components or functions that work with any type, providing flexibility and type safety.

```typescript
function identity<T>(arg: T): T {
  return arg;
}
```

### 12. How do generics constraints work? Why are they useful?
You can constrain generics to ensure they meet certain conditions, such as having certain properties.

```typescript
function logLength<T extends { length: number }>(arg: T): void {
  console.log(arg.length);
}
```

### 13. Describe conditional types and when they can be utilized.
Conditional types allow you to create types that depend on a condition, enabling advanced type manipulation.

```typescript
type IsString<T> = T extends string ? true : false;
```

### 14. What is the difference between the utility types Partial<T> and Pick<T, K>?
`Partial<T>` makes all properties in T optional. `Pick<T, K>` extracts specific properties from T.

```typescript
interface Person {
  name: string;
  age: number;
}

type PartialPerson = Partial<Person>;
type NameOnly = Pick<Person, 'name'>;
```

### 15. In TypeScript, what does keyof do?
`keyof` creates a union of the keys of an object type.

```typescript
interface Person {
  name: string;
  age: number;
}

type PersonKeys = keyof Person; // 'name' | 'age'
```

### 16. How would you handle type-safe error handling with discriminated unions?
Discriminated unions allow you to handle different types in a safe way using a common discriminant property.

```typescript
type Success = { status: "success"; data: string };
type Failure = { status: "failure"; error: string };
type Response = Success | Failure;

function handleResponse(response: Response) {
  if (response.status === "success") {
    console.log(response.data);
  } else {
    console.log(response.error);
  }
}
```

### 17. What are template literal types, and how useful are they?
Template literal types allow you to create new string types by combining unions of string literals, increasing flexibility in working with string types.

```typescript
type Greeting = `Hello, ${string}!`;
```

## TypeScript and OOP (Object-Oriented Programming)

### 18. How does TypeScript use classes? How do these differ from ES6 classes?
TypeScript classes extend ES6 classes with additional type annotations, access modifiers, and interfaces.

```typescript
class Person {
  private name: string;
  
  constructor(name: string) {
    this.name = name;
  }
  
  getName(): string {
    return this.name;
  }
}
```

### 19. What are access modifiers (public, private, protected) in TypeScript?
Access modifiers control the visibility of properties and methods. `public` means accessible everywhere, `private` within the class, and `protected` within the class and subclasses.

### 20. How do abstract classes work in TypeScript, and when should they be used?
Abstract classes define base classes with incomplete functionality, forcing subclasses to implement specific methods.

```typescript
abstract class Animal {
  abstract sound(): void;
  
  move() {
    console.log("Moving...");
  }
}

class Dog extends Animal {
  sound() {
    console.log("Woof!");
  }
}
```

### 21. What is the difference between an Interface and an Abstract Class?
An interface defines a contract (structure) without any implementation, whereas an abstract class can define both abstract methods and concrete methods.

### 22. How can you describe a class in TypeScript that we create inside a function and return outside?
You can create and return a class from within a function to provide encapsulation.

```typescript
function createUser() {
  return class User {
    constructor(public name: string) {}
  };
}

const UserClass = createUser();
const user = new UserClass("John");
```
