import matplotlib.pyplot as plt
import numpy as np
import pickle

# Chargement ...

with open("parametres.txt", "rb") as fp:
    [duree_trame, ordre, omega_v, omega_d, omega_h] = pickle.load(fp)

with open("xapp.txt", "rb") as fp:
    Xapp = pickle.load(fp)
with open("xtest.txt", "rb") as fp:
    Xtest = pickle.load(fp)
Yapp = np.load("yapp.npy")
Ytest = np.load("ytest.npy")

Dist = np.load("dist.npy")

# Prédiction ...

def kppv_predict(Dist, Yapp, K):
    N = Dist.shape[0]
    Ypred = np.zeros(N, dtype=int)
    for i in range(N):
        kppv = Yapp[Dist[i,:].argsort()[:K]]
        Ypred[i] = np.argmax(np.bincount(kppv))
    return Ypred

def evaluation_classifieur(Ytest, Ypred):
    return (Ytest == Ypred).sum() / Ytest.shape[0]

def performance(K):
    Ypred = kppv_predict(Dist, Yapp, K)
    return evaluation_classifieur(Ytest, Ypred)

les_k = [ k for k in range(1,20) ]
les_accuracy = [ performance(k) for k in les_k ]

plt.xlabel('K')
plt.ylabel('Accuracy')
plt.title('Accuracy(K) avec (ordre = ' + str(ordre) + ', oh = ' + str(omega_h) + ', od = ' + str(omega_d) + ', oh = ' + str(omega_h) + ')')
plt.plot(les_k, les_accuracy, 'ro')

index_max = np.asarray(les_accuracy).argsort()[-1]
print('La meilleure Accuracy ' + str(les_accuracy[index_max]) + ' est atteinte pour K = ' + str(les_k[index_max]))
