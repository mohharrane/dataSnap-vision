import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
import os

# Define the Convolutional Neural Network (CNN)
class SimpleDigitCNN(nn.Module):
    def __init__(self):
        super(SimpleDigitCNN, self).__init__()
        # Input shape: (1, 28, 28)
        self.conv1 = nn.Conv2d(1, 32, kernel_size=3, padding=1)
        self.relu1 = nn.ReLU()
        self.pool1 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.relu2 = nn.ReLU()
        self.pool2 = nn.MaxPool2d(kernel_size=2, stride=2)
        
        # After two MaxPool layers (28->14->7), the spatial size is 7x7.
        self.fc1 = nn.Linear(64 * 7 * 7, 128)
        self.relu3 = nn.ReLU()
        self.dropout = nn.Dropout(0.5)
        self.fc2 = nn.Linear(128, 10) # 10 classes (digits 0-9)

    def forward(self, x):
        x = self.pool1(self.relu1(self.conv1(x)))
        x = self.pool2(self.relu2(self.conv2(x)))
        x = x.view(-1, 64 * 7 * 7) # Flatten
        x = self.relu3(self.fc1(x))
        x = self.dropout(x)
        x = self.fc2(x)
        return x

def train_model():
    print("--- 🧠 Starting DataSnap Vision AI Training 🧠 ---")
    print("Downloading the MNIST dataset (70,000 images)...")
    
    # Transformation: Convert images to PyTorch tensors and normalize to range [-1, 1]
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.5,), (0.5,))
    ])

    batch_size = 64

    # Download and load the training data
    trainset = torchvision.datasets.MNIST(root='./data', train=True, download=True, transform=transform)
    trainloader = torch.utils.data.DataLoader(trainset, batch_size=batch_size, shuffle=True)

    # Download and load the test data
    testset = torchvision.datasets.MNIST(root='./data', train=False, download=True, transform=transform)
    testloader = torch.utils.data.DataLoader(testset, batch_size=batch_size, shuffle=False)

    print(f"Dataset loaded! Training images: {len(trainset)}, Testing images: {len(testset)}")

    # Initialize the network, loss function, and optimizer
    model = SimpleDigitCNN()
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)

    epochs = 3 # 3 loops through the whole dataset is enough for good accuracy on MNIST
    
    print("\nTraining the Neural Network...")
    for epoch in range(epochs):
        running_loss = 0.0
        for i, data in enumerate(trainloader, 0):
            inputs, labels = data

            # Zero the parameter gradients
            optimizer.zero_grad()

            # Forward + backward + optimize
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            # Print statistics
            running_loss += loss.item()
            if i % 200 == 199:    # print every 200 mini-batches
                print(f"[Epoch {epoch + 1}, Batch {i + 1:5d}] Loss: {running_loss / 200:.3f}")
                running_loss = 0.0

    print("Finished Training. Testing accuracy...")

    # Test the model
    correct = 0
    total = 0
    with torch.no_grad(): # Don't track gradients during testing
        for data in testloader:
            images, labels = data
            outputs = model(images)
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

    accuracy = 100 * correct / total
    print(f'Accuracy of the AI on the 10000 test images: {accuracy:.2f} %')

    # Save the trained model parameters
    save_path = 'mnist_model.pth'
    torch.save(model.state_dict(), save_path)
    print(f"\n✅ SUCCESS! The intelligent 'Brain' has been saved to '{save_path}'")
    print(f"File size: {os.path.getsize(save_path) / (1024*1024):.2f} MB")

if __name__ == '__main__':
    train_model()
